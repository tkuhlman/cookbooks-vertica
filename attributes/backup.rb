# The backup runs on one machine and pulls from all 5 so that snapshot is consistent across all boxes.
# I can't read a databag in an attributes file but need this set to the icinga attributes can be set so I base
# which one on hostname. It also has the affect of excluding backups in RNDD
if node[:hostname]  =~ /az2-vertica0002/
  node[:vertica][:backups_enabled] = true
else
  node[:vertica][:backups_enabled] = false
end

if node[:vertica][:backups_enabled]
  default[:icinga][:service_checks][:vertica_backup] = {
    :service_description => "vertica_backup",
    :use => "generic-passive-service",
    :freshness_threshold => 86500, #A bit over 1 day to allow for fluctuations in backup time
    :max_check_attempts => 1,
    :servicegroups => ["SOM"],
    :contact_groups => ["som_team"]
  }

  # The actual cron job to do the backup is setup in the backup recipe this just sets up the passive check on the server side
  # It is done this way as there is no way to specify a specific time with these attributes, the attributes here are only
  # to prevent the icinga server from breaking
  default[:icinga][:check_params][:backups_enabled] = {
    :hostgroups => ["role[Vertica-Node]"]
  }

  default[:icinga][:client][:passive_checks_enabled] = {
    "vertica_backup" => true,
  }
end

# Thresholds on the backup time in minutes
node.default[:vertica][:backup_warn_threshold] = '240'
node.default[:vertica][:backup_crit_threshold] = '360'

# Other attributes
node.default[:vertica][:cloudfuse_dir] = '/mnt/swift'
