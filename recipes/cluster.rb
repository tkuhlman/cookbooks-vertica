# Do dynamic setup/configuration based on the specific cluster configuration.
# This recipe should not stand alone but be called from default.rb

vconfig_dir = '/opt/vertica/config' #This is set by the vertica package

#Pull cluster node information, used by many resources in this recipe
node_dbag = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_nodes"), {
  :nodes => { :required => true, :typeof => Hash }, :broadcast => { :required => true, :typeof => String }
})
nodes = node_dbag['nodes']

# Setup the /etc/hosts file on each box, each box in the cluster should know about the others and itself.
# The hosts/ips setup are for the internal cluster communication
nodes.each do |fqdn, ip|
  hostsfile_entry ip do
    action :create
    hostname fqdn
    aliases [ fqdn.split('.')[0] ]
  end
end

# TODO: Setup of the private network, I have yet to implement as the dev boxes are waiting on DC-1945 to hook up their 2nd nics
# It is assumed that eth1 is used on each node in attributes/ufw.rb, I can probably use the interfaces cookbook for this


## Config file setup
template "#{vconfig_dir}/admintools.conf" do
  action :create_if_missing #This file changes with each new db so I must only do the initial setup
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "644"
  source "admintools.conf.erb"
  variables(
    :nodes => nodes,
    :data_dir => node['vertica']['data_dir'],
    :catalog_dir => node['vertica']['catalog_dir']
  )
end

#Spread setup
template "#{vconfig_dir}/vspread.conf" do
  action :create
  owner node['vertica']['spread_user']
  group node['vertica']['dbadmin_group']
  mode "644"
  source "vspread.conf.erb"
  variables(
    :broadcast => node_dbag['broadcast'],
    :ip_list => nodes.values.sort,
    :user => node['vertica']['spread_user'],
    :group => node['vertica']['dbadmin_group']
  )
end

#Figure out what box in the cluster this is, ie which ip is in both ohai and the cluster list
all_local_ips = node['network']['interfaces'].values.map { |info| info['addresses'].keys }.flatten 
local_ip = (nodes.values & all_local_ips)[0]
template "/etc/spreadd" do
  action :create
  owner 'root'
  group 'root'
  mode "644"
  source "spreadd.erb"
  variables(
    :mangled_ip => local_ip.split('.').map { |octet| "%03d" % octet }.join,
    :user => node['vertica']['spread_user']
  )
end

