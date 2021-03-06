##Cluster Setup - defaults to standalone
node.default[:vertica][:cluster] = false
node.default[:vertica][:cluster_name] = ''

## Node Setup
node.default[:vertica][:dbadmin_user] = 'dbadmin'
node.default[:vertica][:dbadmin_home] = '/home/dbadmin'
# Note the vertica group is used to enable ssh public key access so changing it requires
# both a new ssh databag and updated authorised_groups attribute
node.default[:vertica][:dbadmin_group] = 'verticadba'
# DB drive locations, data should be a large raid array dedicated to vertica
# It is assumed the os setup and catalog_dir are setup during os install, the data_dir and dev will be setup by chef
node.default[:vertica][:catalog_dir] = '/var/vertica/catalog'
node.default[:vertica][:data_dir] = '/var/vertica/data'
node.default[:vertica][:data_dev] = '' # Set to something like /dev/sdb1 to format and prepare a vertica data disk
node.default[:vertica][:cluster_interface] = ''  # Set to a network device (ie eth1) to set this up as a cluster interface
# Package version
node.default[:vertica][:version] = '7.0.1-0'

#Sysctl settings
#This style is picked up by the sysctl cookbook in HP Cloud basenode
node.default[:sysctl]['vm.min_free_kbytes'] = '4096'
node.default[:sysctl]['vm.max_map_count'] = (node[:memory][:total].to_i/16).to_s #ram in KB/16
#This style is used by the sysctl community cookbook
node.default[:sysctl][:params][:vm][:min_free_kbytes] = '4096'
node.default[:sysctl][:params][:vm][:max_map_count] = (node[:memory][:total].to_i/16).to_s #ram in KB/16

#This is used by the system cookbook to set kernel params if that cookbook is loaded
node.default[:system][:grub][:cmdline_linux_default] = 'quiet elevator=deadline'
