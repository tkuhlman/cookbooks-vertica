# Setup a vertica node

# If the nodes data bag exists consider this a cluster
if node.default[:vertica][:cluster_name] == '' and search(:vertica, 'id:nodes*').empty?
  node.default[:vertica][:standalone] = true
else
  node.default[:vertica][:standalone] = false
end

# Prep for installation
include_recipe 'vertica::node_dependencies'

# For chef solo it is assumed there is not setup apt repo with the vertica packages but rather they are in /vagrant
if Chef::Config[:solo]
  dpkg_package "vertica" do
    action :install
    source "/vagrant/vertica_#{node[:vertica][:version]}_amd64.deb"
    version node[:vertica][:version]
  end

  package "libgfortran3" do
    action :install
  end
    
  dpkg_package "vertica-R-lang" do
    action :install
    source "/vagrant/vertica-r-lang_#{node[:vertica][:version]}_amd64.deb"
    version node[:vertica][:r_version]
  end
else
  package "vertica" do
    action :install
    version node[:vertica][:version]
  end

  package "vertica-R-lang" do
    action :install
    version node[:vertica][:r_version]
  end
end

# Static configuration common to all nodes in any cluster
include_recipe 'vertica::node_setup'

#Sets up the config specific to a cluster
include_recipe 'vertica::cluster'

## start services
#Note: Nothing triggers a restart of the services, this cookbook largely sets up a node then vertica admin tools take
#the configuration from there. They are then responsible for any service restarts.
service 'vertica_agent' do
  action [ :enable, :start ]
  supports :status => true, :restart => true
end

#The verticad daemon will fail startup until it has a valid database, so startup is done with db creation
if node[:os_version] =~ /hlinux/  # in hLinux ntpd = ntp
  package 'ntp' do
    action :install
  end
  bash 'change ntpd in vertica init' do
    action :run
    code 'cp /opt/vertica/sbin/verticad /opt/vertica/sbin/verticad-dist && sed s/ntpd/ntp/g /opt/vertica/sbin/verticad-dist > /opt/vertica/sbin/verticad'
    not_if do ::File.exists?('/opt/vertica/sbin/verticad-dist') end
  end
end

service 'verticad' do
  action :enable
  supports :status => true, :restart => true
end

if node.recipes.include?('vertica_client::python')
  include_recipe 'vertica::monitor'
end

unless Chef::Config[:solo] # Since chef solo is mostly vagrant no backup is included
  include_recipe 'vertica::backup'
end

if node.default[:vertica][:standalone]
  include_recipe 'vertica::create_db'
end
