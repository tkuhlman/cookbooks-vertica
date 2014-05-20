# Sets up a backup job for each host that pushed data to swift
# The config and setup goes on each vertica node but only one is actually activated to run the job, it starts the job on the others
# This is so the backup is consistent across all 5 nodes and is a core assumption of the vbr tool

require 'zlib'

package 'vertica-utils' do
  action :upgrade
end

## Pull the data bags
creds = data_bag_item("vertica", "backup_credentials#{node[:vertica][:cluster_name]}")
#Pull cluster node information, ** This is copied from the cluster recipe which primarily uses this, it is important they match
nodes = data_bag_item("vertica", "nodes#{node[:vertica][:cluster_name]}")['nodes']
ips = []
nodes.each { | node, value| ips.push(value['ip']) }
ips.sort!

## The backup configs
directory node[:vertica][:backup_dir] do
  action :create
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode '775'
end

snapshot_name = node[:domain].gsub('.', '_') + "_#{creds['dbname']}"
if node[:hostname]  =~ /az2-vertica0002/ # cron runs on the box which does the vbr command at least 1 hour before the rsyncs
  run_hour = '3'
  run_vbr = true
else
  run_hour = '5'
  run_vbr = false
end

template "/opt/vertica/config/#{creds['dbname']}_backup.yaml" do
  action :create
  source 'backup.yaml.erb'
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode '600'
  variables(
    :dbname => creds['dbname'],
    :run_vbr => run_vbr,
    :snapshot_name => snapshot_name,
    :swift_user => creds['swift_user'],
    :swift_tenant => creds['swift_tenant'],
    :swift_key => creds['swift_key'],
    :url => creds['url'],
    :vbr_config => "/opt/vertica/config/#{creds['dbname']}_backup.ini"
  )
end

template "/opt/vertica/config/#{creds['dbname']}_backup.ini" do
  action :create
  source 'backup.ini.erb'
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode '600'
  variables(
    :dbname => creds['dbname'],
    :dbuser => creds['dbuser'],
    :dbpass => creds['dbpass'],
    :ips => ips,
    :snapshot_name => snapshot_name
  )
end

# In order for the dbadmin_user to run the backup job and report to icinga it must be in the nagios group
group 'nagios' do
  action :modify
  members node[:vertica][:dbadmin_user]
  append true
end

# The cronjob is not setup via the standard mechanism for nsca so I can use a specific time
# but it still relies on monitoring's nsca_wrapper and that the params match the icinga setup in attributes/backup.rb
nsca_wrapper = "/usr/local/bin/nsca_wrapper" #Provided by the monitoring roles

if node[:continent] == 'dev'  # Fake backups for dev
  backup_command = "#{nsca_wrapper} -C 'echo No backups done in development' -S 'vertica_backup' -H #{node[:fqdn]}"
else
  backup_command = "#{nsca_wrapper} -C '/usr/bin/vertica_backup /opt/vertica/config/#{creds[:dbname]}_backup.yaml' -S 'vertica_backup' -H #{node[:fqdn]}"
end

cron 'vertica_backup' do
  action :create
  user node[:vertica][:dbadmin_user]
  hour run_hour
  minute Zlib.crc32(node[:fqdn]) % 60
  command backup_command
end
