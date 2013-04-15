# Do dynamic setup/configuration based on the specific cluster configuration.
# This recipe should not stand alone but be called from default.rb

vconfig_dir = '/opt/vertica/config' #This is set by the vertica package

#Pull cluster node information, used by many resources in this recipe
nodes = normalize(get_data_bag_item("vertica", node['vertica']['cluster_name'] + "_nodes"), {
  :nodes => { :required => true, :typeof => Hash, :metadata => {
    :"*" => { :typeof => Hash, :required => true, :metadata => {
      :ip => { :required => true, :typeof => String }, 
      :broadcast => { :required => true, :typeof => String },
      :netmask => { :required => true, :typeof => String },
      :network => { :required => true, :typeof => String }
      }
    } }
  }
})['nodes']
ips = []
nodes.each { | node, value| ips.push(value['ip']) }
ips.sort!

# Setup the /etc/hosts file on each box, each box in the cluster should know about the others and itself.
# The hosts/ips setup are for the internal cluster communication
nodes.each do |fqdn, info|
  ip = info['ip']
  hostsfile_entry ip do
    action :create
    hostname fqdn
    aliases [ fqdn.split('.')[0] ]
  end
end

## Config file setup
template "#{vconfig_dir}/admintools.conf" do
  action :create_if_missing #This file changes with each new db so I must only do the initial setup
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_group']
  mode "660"
  source "admintools.conf.erb"
  variables(
    :hosts => nodes,
    :ips => ips,
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
    :nodes => nodes,
    :user => node['vertica']['spread_user'],
    :group => node['vertica']['dbadmin_group']
  )
end

# assumes the cluster interface name contains the hostname
local_cluster_name = nodes.keys.select { |node_name| node_name.include? node['hostname'] }[0]
local_net = nodes[local_cluster_name]
template "/etc/spreadd" do
  action :create
  owner 'root'
  group 'root'
  mode "644"
  source "spreadd.erb"
  variables(
    :mangled_ip => local_net['ip'].split('.').map { |octet| "%03d" % octet }.join,
    :user => node['vertica']['spread_user']
  )
end

# Setup eth1 as the cluster interface, first setup interfaces.d then eth1
directory "/etc/network/interfaces.d" do
  action :create
  owner 'root'
  group 'root'
  mode '775'
end

execute "echo 'source /etc/network/interfaces.d/*' >> /etc/network/interfaces" do
  action :run
  user 'root'
  not_if "grep 'source /etc/network/interfaces.d/*' /etc/network/interfaces"
end

execute 'ifup eth1' do
  action :nothing
  user 'root'
end

template "/etc/network/interfaces.d/vertica_cluster" do
  action :create
  owner 'root'
  group 'root'
  mode "644"
  source "cluster_interface.erb"
  variables(
    :ip => local_net['ip'],
    :broadcast => local_net['broadcast'],
    :netmask => local_net['netmask'],
    :network => local_net['network']
  )
  notifies :run, "execute[ifup eth1]"
end

