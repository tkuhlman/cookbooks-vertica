# Sets up a backup job for each host that pushed data to swift
# The config and setup goes on each vertica node but only one is actually activated to run the job, it starts the job on the others
# This is so the backup is consistent across all 5 nodes and is a core assumption of the vbr tool

# The backup script is in this package with
package 'sommon' do
  action :upgrade
end

## Pull the data bags
creds = normalize(get_data_bag_item("vertica", "#{node['vertica']['cluster_name']}_backup_credentials", { :encrypted => true}), {
  :dbname => { :required => true, :typeof => String },
  :dbpass => { :required => true, :typeof => String },
  :dbuser => { :required => true, :typeof => String },
  :swift_key => { :required => true, :typeof => String },
  :swift_tenant => { :required => true, :typeof => String },
  :swift_user => { :required => true, :typeof => String },
  :url => { :required => true, :typeof => String }

})
#Pull cluster node information, ** This is copied from the cluster recipe which primarily uses this, it is important they match
nodes = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_nodes"), {
  :nodes => { :required => true, :typeof => Hash, :metadata => {
    :"*" => { :typeof => Hash, :required => true, :metadata => {
      :ip => { :required => true, :typeof => String }, 
      :broadcast => { :required => true, :typeof => String },
      :netmask => { :required => true, :typeof => String },
      :network => { :required => true, :typeof => String },
      :routes => { :typeof => Array, :default => [] }
      }
    } }
  }
})['nodes']
ips = []
nodes.each { | node, value| ips.push(value['ip']) }
ips.sort!

## The swift setup, using cloudfuse
package 'cloudfuse' do
  action :upgrade
end

directory node[:vertica][:cloudfuse_dir] do
  action :create
  owner 'root'
  group node['vertica']['dbadmin_group']
  mode '775'
  not_if "mount |grep /mnt/swift" #When cloudfuse mounts the dir not even root can read it and so the checks to verify fail
end

template "/root/.cloudfuse" do #It seems the mount command still looks for it in /root though it is run by dbadmin
  action :create
  source 'cloudfuse.erb'
  owner 'root'
  group node['vertica']['dbadmin_group']
  mode '640'
  variables(
    :swift_user => creds[:swift_user],
    :swift_tenant => creds[:swift_tenant],
    :swift_key => creds[:swift_key],
    :url => creds[:url]
  )
end

# The backup job mounts/unmounts this just puts it in fstab.
mount node[:vertica][:cloudfuse_dir] do
  action :enable
  device 'cloudfuse'
  fstype 'fuse'
  options "defaults,noauto,user"
end

## The backup configs
directory node[:vertica][:vbr_dir] do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '775'
end

snapshot_name = node[:domain].gsub('.', '_') + "_#{creds[:dbname]}"
if node[:hostname]  =~ /az2-vertica0002/ # cron runs on the box which does the vbr command at least 1 hour before the rsyncs
  run_hour = '3'
  run_vbr = true
else
  run_hour = '5'
  run_vbr = false
end

template "/opt/vertica/config/#{creds[:dbname]}_backup.yaml" do
  action :create
  source 'backup.yaml.erb'
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '644'
  variables(
    :dbname => creds[:dbname],
    :run_vbr => run_vbr,
    :snapshot_name => snapshot_name,
    :vbr_config => "/opt/vertica/config/#{creds[:dbname]}_backup.ini"
  )
end

template "/opt/vertica/config/#{creds[:dbname]}_backup.ini" do
  action :create
  source 'backup.ini.erb'
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '600'
  variables(
    :dbname => creds[:dbname],
    :dbuser => creds[:dbuser],
    :dbpass => creds[:dbpass],
    :ips => ips,
    :snapshot_name => snapshot_name
  )
end

# In order for the dbadmin_user to run the backup job and report to icinga it must be in the nagios group
group 'nagios' do
  action :modify
  members node['vertica']['dbadmin_user']
  append true
end

# The cronjob is not setup via the standard mechanism for nsca so I can use a specific time
# but it still relies on monitoring's nsca_wrapper and that the params match the icinga setup in attributes/backup.rb
nsca_wrapper = "/usr/local/bin/nsca_wrapper" #Provided by the monitoring roles

if node[:continent] == 'dev' and node[:area] != 'stb'  # Fake backups for dev
  backup_command = "#{nsca_wrapper} -C 'echo No backups done in development' -S 'vertica_backup' -H #{node[:fqdn]}"
else
  backup_command = "#{nsca_wrapper} -C '/usr/bin/vertica_backup.py /opt/vertica/config/#{creds[:dbname]}_backup.yaml' -S 'vertica_backup' -H #{node[:fqdn]}"
end

cron 'vertica_backup' do
  action :create
  user node['vertica']['dbadmin_user']
  hour run_hour
  minute node[:fqdn].hash % 60
  command backup_command
end
