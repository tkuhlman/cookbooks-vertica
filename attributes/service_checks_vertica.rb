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

#Enable passive checks
default[:icinga][:client][:passive_checks_enabled] = {
  "vertica_daemon" => true,
  "spread_daemon" => true
}
