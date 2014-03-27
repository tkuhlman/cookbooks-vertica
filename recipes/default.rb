# Setup a vertica node

# If the nodes data bag exists consider this a cluster
# !! Todo - right now this is not using the hp_common_functions but the recipe itself its.
if Chef::Config[:solo]
  node[:vertica][:is_standalone] = true
else
  node[:vertica][:is_standalone] = search(:vertica, 'id:nodes*').empty?
end

# Prep for installation
include_recipe 'vertica::node_dependencies'

package "vertica" do
  action :install
  version node[:vertica][:version]
end

package "vertica-R-lang" do
  action :install
  version node[:vertica][:r_version]
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

#The verticad daemon will fail startup until it has a valid database. As this cookbook does not setup a db I enable it only
#Upon database setup it will be started by the vertica admintools
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

if Chef::Config[:solo]
  include_recipe 'vertica::create_db'
end
