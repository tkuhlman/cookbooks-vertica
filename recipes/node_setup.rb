# Setup the various bit of configuration every node needs but which aren't handled in the package from vertica
# This recipe should not stand alone but be called from default.rb

include_recipe 'vertica::node_users'
include_recipe 'vertica::node_disks'

vconfig_dir = '/opt/vertica/config' #This is set by the vertica package

#Directory setup - a few of these are setup by the package but as root and they need to be owned by dbadmin
directory "#{vconfig_dir}" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '775'
end
directory '/opt/vertica/log' do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '775'
end
directory "#{vconfig_dir}/share" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode '775'
end

# init script inks to setup, the services are enabled in default.rb
init_links = {
  "/etc/init.d/vertica_agent" => "/opt/vertica/sbin/vertica_agent",
  "/etc/init.d/verticad" => "/opt/vertica/sbin/verticad",
  "/etc/init.d/spreadd" => "/opt/vertica/spread/daemon/spreadd.deb"
}
init_links.each do |path, target| 
  link path do
    action :create
    to target
  end
end

# The spread logroation file is included via /etc/logrotate.d/vertica that comes in the package
cookbook_file "#{vconfig_dir}/logrotate/spread_daemon.logrotate" do
  action :create_if_missing
  source "spread_daemon.logrotate"
  owner 'root'
  group 'root'
  mode "664"
end

# EULA acceptance makes this file, with a timestamp, I'm not bothering to update the timestamp
cookbook_file "#{vconfig_dir}/d5415f948449e9d4c421b568f2411140.dat" do
  action :create_if_missing
  source "d5415f948449e9d4c421b568f2411140.dat"
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "775"
end

# The license
license_key = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_license", { :encrypted => true}), {
  :key => { :required => true, :typeof => String }
})['key']

file "#{vconfig_dir}/share/license.key" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "644"
  content license_key
end

## SSL key
# The process for creation of the key is in the ssl_key_gen function in /opt/vertica/bin/verticaInstall.py
# After the install script the pem and key file are only on the primary, I distribute to all boxes
agent_ssl = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_agent_ssl", { :encrypted => true}), {
  :key => { :required => true, :typeof => String }, :cert => { :required => true, :typeof => String }
})
agent_key = agent_ssl['key']
agent_cert = agent_ssl['cert']

file "#{vconfig_dir}/share/agent.key" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "400"
  content agent_key
end
file "#{vconfig_dir}/share/agent.cert" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "400"
  content agent_cert
end
file "#{vconfig_dir}/share/agent.pem" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "400"
  content agent_cert + agent_key
end

# SOM DB ssl cert, this is the cert clients see when connecting, the certs for each zone come from the security team
# Vertica actually requires it in the db specific dir but it is not created until after the db so I put them in the root
# catalog dir and link later after db creation
server_ssl = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_server_ssl", { :encrypted => true}), {
  :key => { :required => true, :typeof => String }, :cert => { :required => true, :typeof => String }
})
server_key = server_ssl['key']
server_cert = server_ssl['cert']

file "#{node['vertica']['catalog_dir']}/server.key" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "400"
  content server_key
end
file "#{node['vertica']['catalog_dir']}/server.crt" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "444"
  content server_cert
end
