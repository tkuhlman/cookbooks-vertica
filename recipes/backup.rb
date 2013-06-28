# Sets up a backup job for each host that pushed data to swift
# The config and setup goes on each vertica node but only one is actually activated to run the job, it starts the job on the others
# This is so the backup is consistent across all 5 nodes and is a core assumption of the vbr tool

# Pull the edb
creds = normalize(get_data_bag_item("vertica", "#{node['vertica']['cluster_name']}_backup_credentials", { :encrypted => true}), {
  :url => { :required => true, :typeof => String },
  :swift_user => { :required => true, :typeof => String },
  :swift_tenant => { :required => true, :typeof => String },
  :swift_key => { :required => true, :typeof => String },
  :dbname => { :required => true, :typeof => String },
  :db_user => { :required => true, :typeof => String },
  :db_pass => { :required => true, :typeof => String }
})

# The swift setup, using cloudfuse
package 'cloudfuse' do
  action :upgrade
end

directory node[:vertica][:cloudfuse_dir] do
  action :create
  owner 'root'
  group node['vertica']['dbadmin_group']
  mode '775'
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

# The backup config
template "/opt/vertica/config/#{creds[:dbname]}_backup.ini" do
  action :create
  source 'backup.ini.erb'
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '640'
  variables(
    :dbname => creds[:dbname],
    :user => creds[:db_user],
    :password => creds[:db_pass]
  )
end

# The vbr command uses rsync but doesn't allow you to modify the rysnc arguments, however cloudfuse requires the -O argument
# so I have to patch it. Patching the actual vertica package could be done but that currently is an upstream package with no
# custom modifications
package 'patch' do
  action :install
end

execute 'patch_vbr' do
  action :nothing
  command "patch -p0 -o vbr-patched.py vbr.py vbr.patch; chmod 755 vbr-patched.py"
  cwd "/opt/vertica/bin"
end

cookbook_file '/opt/vertica/bin/vbr.patch' do
  action :create
  source "vbr.patch"
  notifies :run, "execute[patch_vbr]"
end

# I have a wrapper script around vbr that is used to provide the correct output for icinga as well as alerting in warning state if
# the time to backup is too long
template "/usr/local/bin/check_vertica_backup" do
  action :create
  source 'check_vertica_backup.erb'
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '750'
  variables(
    :backup_dir => node[:vertica][:cloudfuse_dir],
    :config_file => "/opt/vertica/config/#{creds[:dbname]}_backup.ini",
    :warn => node[:vertica][:backup_warn_threshold],
    :crit => node[:vertica][:backup_crit_threshold] 
  )
end

# In order for the dbadmin_user to run the backup job and report to icinga it must be in the nagios group
group 'nagios' do
  action :modify
  members node['vertica']['dbadmin_user']
  append true
end

# The cronjob, only runs on one machine, this is not setup via the standard mechanism for nsca so I can specify a specific time
# but it still relies on monitorings nsca_wrapper and the params match the icinga setup in attributes/backup.rb
nsca_wrapper = "/usr/local/bin/nsca_wrapper" #Provided by the monitoring roles
if node[:vertica][:backups_enabled]
  cron 'vertica_backup' do
    action :create
    user node['vertica']['dbadmin_user']
    hour "5"
    minute "12"
    command "#{nsca_wrapper} -C /usr/local/bin/check_vertica_backup -S 'vertica_backup' -H #{node[:fqdn]}"
  end
else
  cron 'vertica_backup' do
    action :create
    user node['vertica']['dbadmin_user']
    hour "5"
    minute "12"
    command "#{nsca_wrapper} -C 'echo Backup disabled on this node.' -S 'vertica_backup' -H #{node[:fqdn]}"
  end
end
