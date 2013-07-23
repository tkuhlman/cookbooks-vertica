default[:icinga][:service_checks][:vertica_backup] = {
  :service_description => "vertica_backup",
  :use => "generic-passive-service",
  :freshness_threshold => 108000, #30 hours to allow for fluctuations in backup time
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
node.default[:vertica][:backup_warn_threshold] = '960'
node.default[:vertica][:backup_crit_threshold] = '1200'

# Other attributes
node.default[:vertica][:cloudfuse_dir] = '/mnt/swift'
# This should be based on node[:vertica][:data_dir] but since that attribute is defined in a different file
# it must be loaded first and this is happening inconsistenly across environments
node.default[:vertica][:vbr_dir] = "/var/vertica/data/backup"
