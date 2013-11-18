# Passive checks are enabled in the role

#Active check from the icinga server to the vertica sql tcp port
default[:icinga][:service_checks][:vertica_sql] = {
  :service_description => "vertica_sql",
  :use => "generic-service",
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"],
  :check_command => "check_tcp!5433",
  :max_check_attempts => 2,
  :normal_check_interval => 180 #For active services this is seconds
}
default[:icinga][:check_params][:vertica_sql] = {
  :hostgroups => ["role[Vertica-Node]"]
}

#Passive check running on the node to verify spread daemon is running
default[:icinga][:service_checks][:spread_daemon] = {
  :service_description => "spread_daemon",
  :use => "generic-passive-service",
  :freshness_threshold => 300,
  :max_check_attempts => 2,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}
default[:icinga][:check_params][:spread_daemon] = {
  :user => "nagios",
  :hostgroups => ["role[Vertica-Node]"],
  :check_interval => 1, #For passive services this is minutes
  :command => "/usr/lib/nagios/plugins/check_procs -c 1: -C spread"
}

#Graphite endpoint is the opposite region for uswest/useast
if node[:domain] == 'uswest.hpcloud.net'
  graphite = 'graphite.useast.hpcloud.net'
elsif node[:domain] == 'useast.hpcloud.net' 
  graphite = 'graphite.uswest.hpcloud.net'
else
  graphite = 'graphite.' + node[:domain]
end

#Thresholds
default[:icinga][:service_checks][:vertica_request_queue_depth] = {
  :service_description => "vertica_request_queue_depth",
  :use => "generic-passive-service",
  :freshness_threshold => 900,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}
default[:icinga][:check_params][:vertica_request_queue_depth] = {
  :user => "nagios",
  :hostgroups => ["role[Vertica-Node]"],
  :check_interval => 5, #For passive services this is minutes
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-request_queue_depth-gauge--value.~&from=-15minutes&rawData=true -w 5 -c 10"
}

default[:icinga][:service_checks][:vertica_sessions] = {
  :service_description => "vertica_sessions",
  :use => "generic-passive-service",
  :freshness_threshold => 900,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}
default[:icinga][:check_params][:vertica_sessions] = {
  :user => "nagios",
  :hostgroups => ["role[Vertica-Node]"],
  :check_interval => 5, #For passive services this is minutes
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-sessions-gauge--value.~&from=-15minutes&rawData=true -w 150 -c 175"
}

default[:icinga][:service_checks][:vertica_percent_disk_free] = {
  :service_description => "vertica_percent_disk_free",
  :use => "generic-passive-service",
  :freshness_threshold => 7200,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}
default[:icinga][:check_params][:vertica_percent_disk_free] = {
  :user => "nagios",
  :hostgroups => ["role[Vertica-Node]"],
  :check_interval => 60, #For passive services this is minutes
  # The nagios plugin doesn't fully escape so the \\ before an %2C is needed
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=minSeries(Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-data_disk_percent_free-percent--value.~\\%2CMonitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-catalog_disk_percent_free-percent--value.~)&from=-60minutes&rawData=true -w 40: -c 15: -f min"
}
