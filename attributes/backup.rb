default[:icinga][:service_checks][:vertica_backup] = {
  :service_description => "vertica_backup",
  :use => "generic-passive-service",
  :freshness_threshold => 172800, #48 hours to allow for large fluctuations in backup time between primary/secondary days
  :max_check_attempts => 1,
  :flap_detection_enabled => 0,
  :servicegroups => ["SOM"],
  :contact_groups => ["som_team"]
}

# The actual cron job to do the backup is setup in the backup recipe this just sets up the passive check on the server side
# It is done this way as there is no way to specify a specific time with these attributes
default[:icinga][:check_params][:vertica_backup] = {
  :hostgroups => ["role[Vertica-Node]"]
}

# Thresholds on the backup time in minutes
node.default[:vertica][:backup_warn_threshold] = '1320' #22 hours

# Other attributes
# This should be based on node[:vertica][:data_dir] but since that attribute is defined in a different file
# it must be loaded first and this is happening inconsistenly across environments
node.default[:vertica][:backup_dir] = "/var/vertica/data/backup"
node.default[:vertica][:backup_retain] = 7 # keep 7 backups

# Logs to backup
node.default[:mon_log_backup][:logs][:vertica] = [
  '/opt/vertica/log/',
  '/var/vertica/catalog/som/v_som_node*_catalog/vertica.log.1.gz' #These logs are large so just backup the most recently complete
]
