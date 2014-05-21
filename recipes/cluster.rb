# Do dynamic setup/configuration based on the specific cluster configuration.
# This recipe should not stand alone but be called from default.rb

vconfig_dir = '/opt/vertica/config' #This is set by the vertica package

#Pull cluster node information, used by many resources in this recipe
if node[:vertica][:cluster]
  nodes = data_bag_item("vertica", "nodes#{node[:vertica][:cluster_name]}")['nodes']
  local_cluster_name = nodes.keys.select { |node_name| node_name.include? node['hostname'] }[0]
  local_net = nodes[local_cluster_name]
else
  nodes = { :localhost => {
      'ip' => '127.0.0.1',
      'broadcast' => '127.255.255.255',
      'network' => '127.0.0.0',
      'netmask' => '255.0.0.0'
    } 
  }
  local_net = nodes[:localhost]
end

ips = []
nodes.each { | node, value| ips.push(value['ip']) }
ips.sort!

## Config file setup
template "#{vconfig_dir}/admintools.conf" do
  action :create_if_missing #This file changes with each new db so I must only do the initial setup
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode "660"
  source "admintools.conf.erb"
  variables(
    :ips => ips,
    :data_dir => node[:vertica][:data_dir],
    :catalog_dir => node[:vertica][:catalog_dir]
  )
end

if node[:vertica][:cluster]
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

  if node[:vertica][:cluster_interface] != ''
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

    execute "ifup" do
      command "ifup #{node[:vertica][:cluster_interface]}"
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
        :ip => local_net[:ip],
        :broadcast => local_net[:broadcast],
        :netmask => local_net[:netmask],
        :network => local_net[:network],
        :routes => local_net[:routes]
      )
      notifies :run, "execute[ifup]"
    end
  end
end
