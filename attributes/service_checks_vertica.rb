#Defines the service group
default[:icinga][:server][:servicegroups][:SOM] = {
  :servicegroup_name => "SOM",
  :alias => "SOM"
}

#Active check from the icinga server to the vertica sql tcp port
default[:icinga][:service_checks][:vertica_sql] = {
  :service_description => "vertica_sql",
  :use => "generic-service",
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"],
  :check_command => "check_tcp!5433",
  :normal_check_interval => 180 #For active services this is seconds
}
default[:icinga][:check_params][:vertica_sql] = {
  :hostgroups => ["role[Vertica-Node]"]
}

#Passive check running on the node to verify vertica daemon is running
default[:icinga][:service_checks][:vertica_daemon] = {
  :service_description => "vertica_daemon",
  :use => "generic-passive-service",
  :freshness_threshold => 300,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}
default[:icinga][:check_params][:vertica_daemon] = {
  :user => "nagios",
  :hostgroups => ["role[Vertica-Node]"],
  :check_interval => 1, #For passive services this is minutes
  :command => "/usr/lib/nagios/plugins/check_procs -c 1: -C vertica"
}

#Passive check running on the node to verify spread daemon is running
default[:icinga][:service_checks][:spread_daemon] = {
  :service_description => "spread_daemon",
  :use => "generic-passive-service",
  :freshness_threshold => 300,
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
  :check_interval => 3, #For passive services this is minutes
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-request_queue_depth-gauge--value.~&from-5minutes&rawData=true -w 5 -c 10"
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
  :check_interval => 3, #For passive services this is minutes
  # The nagios plugin doesn't fully escape so the \\ before an %2C is needed
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=sumSeries(Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-active_system_session_count-gauge--value.~\\%2CMonitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-active_user_session_count-gauge--value.~)&from-5minutes&rawData=true -w 100 -c 150"
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
  :command => "/usr/bin/check_graphite -n yes -u http://#{graphite}/render/?target=scale(divideSeries(Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-disk_space_used_mb-gauge--value.~\\%2CsumSeries(Monitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-disk_space_used_mb-gauge--value.~\\%2CMonitoring.#{node[:fqdn].gsub('.', '_')}.vertica.vertica-disk_space_free_mb-gauge--value.~))\\%2C100)&from-60minutes&rawData=true -w 60 -c 75"
}

#Enable passive checks
default[:icinga][:client][:passive_checks_enabled] = {
  "vertica_daemon" => true,
  "spread_daemon" => true,
  "vertica_request_queue_depth" => true,
  "vertica_sessions" => true,
  "vertica_percent_disk_free" => true
}
