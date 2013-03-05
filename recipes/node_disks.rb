# Setup the disks used by Vertica
# This recipe should not stand alone but be included from another
# It is assumed that the catalog drive is setup in fstab during the os install but that the data drive formatting and adding to fstab

# create the data partition and format
hdd_dev = node['vertica']['data_dev'].gsub(/\d/, '') #strips trailing numbers from dev
execute "create partition #{node['vertica']['data_dev']}" do
  action :run
  command "parted #{hdd_dev} --script mklabel gpt && parted #{hdd_dev} --script -- mkpart primary 0 -1"
  user 'root'
  not_if "ls #{node['vertica']['data_dev']}"
end

execute "format #{node['vertica']['data_dev']}" do
  action :run
  command "mkfs.ext4 #{node['vertica']['data_dev']}"
  user 'root'
  not_if "mount |grep #{node['vertica']['data_dev']} || fsck #{node['vertica']['data_dev']}" 
end

# Setup the catalog and data paths ownership
[ node['vertica']['data_dir'], node['vertica']['catalog_dir'] ].each do |dir|
  directory dir do
    action :create
    owner node['vertica']['dbadmin_user']
    group node['vertica']['dbadmin_group']
    mode '770'
    recursive true
  end
end

# Mount the data partition and add to fstab
mount node['vertica']['data_dir'] do
  action [ :mount, :enable ]
  device node['vertica']['data_dev']
  fstype 'ext4'
end

#Change the I/O scheduler for vertica to deadline, this does it now, it is done on boot by the
#kernel boot option "elevator=deadline" set by the system cookbook but defined in the attribute [:system][:grub][:cmdline_linux_default]
dev_short = hdd_dev.split('/')[-1]
bash "set_deadline_scheduler" do
  action :run
  code "echo deadline > /sys/block/#{dev_short}/queue/scheduler"
  not_if "grep \'\\[deadline\\]\' /sys/block/#{dev_short}/queue/scheduler"
  user "root"
  ignore_failure true
end

#Set the data drive readahead to 2048, this doesn't happen on boot but will after the first chef run
bash "set_readahead" do
  action :run
  code "blockdev --setra 2048 #{hdd_dev}"
  not_if "blockdev --getra #{hdd_dev}| grep 2048"
  user "root"
  ignore_failure true
end
