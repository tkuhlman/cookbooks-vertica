##Cluster Setup
node.default['vertica']['cluster_name'] = 'default'

## Node Setup
node.default['vertica']['dbadmin_user'] = 'dbadmin'
node.default['vertica']['dbadmin_home'] = '/home/dbadmin'
# Note the vertica group is used to enable ssh public key access so changing it requires
# both a new ssh databag and updated authorised_groups attribute
node.default['vertica']['dbadmin_group'] = 'verticadba'
node.default['vertica']['spread_user'] = 'spread'
# DB drive locations, data should be a large raid array dedicated to vertica
# It is assumed the os setup and catalog_dir are setup during os install, the data_dir and dev will be setup by chef
node.default['vertica']['catalog_dir'] = '/var/vertica/catalog'
node.default['vertica']['data_dir'] = '/var/vertica/data'
node.default['vertica']['data_dev'] = '/dev/sdb1'
# Package version
node.default['version_pins']['vertica']['vertica']['version'] = '6.1.1-0'
