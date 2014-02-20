# Sets up local monitoring of the Vertica database
# This includes scripts used for both icinga and collectd and the config for collectd
# The config for icinga is primarily done in attributes/service_checks_vertica.rb

package 'sommon' do
  action :upgrade
end

vertica_client_python 'monitor' do
  action :create
end

template '/opt/collectd/etc/collectd.d/collectd-python.conf' do
  action :create
  source 'collectd-python.conf.erb'
  owner 'root'
  group 'root'
  mode '644'
    #The service is defined in the collectd::collectd-Agent recipe which is assumed to be loaded.
  notifies :restart, "service[collectd]"
end

# Rules for ossec, attributes define the log files to watch
ossec_rulefile 'vertica_rules.xml' do
  action :create
end
