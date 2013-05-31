# Setup a vertica node

# Prep for installation
include_recipe 'vertica::node_dependencies'

package "vertica" do
  action :install
  version pinned_version('vertica')
end

package "vertica-r-lang" do
  action :install
end

# Static configuration common to all nodes in any cluster
include_recipe 'vertica::node_setup'

#Sets up the config specific to a cluster
include_recipe 'vertica::cluster'

## start services
#Note: Nothing triggers a restart of the services, this cookbook largely sets up a node then vertica admin tools take
#the configuration from there. They are then responsible for any service restarts.
%w[ spreadd vertica_agent ].each do |svc_name| #note spreadd must be first
  service svc_name do
    action [ :enable, :start ]
    supports :status => true, :restart => true
  end
end

#The verticad daemon will fail startup until it has a valid database. As this cookbook does not setup a db I enable it only
#Upon database setup it will be started by the vertica admintools
service 'verticad' do
  action :enable
  supports :status => true, :restart => true
end

include_recipe 'vertica::monitor'
