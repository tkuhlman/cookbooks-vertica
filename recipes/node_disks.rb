# Setup the disks used by Vertica
# This recipe should not stand alone but be included from another

# Setup the catalog and data paths
[ node['vertica']['data_dir'], node['vertica']['catalog_dir'] ].each do |dir|
  directory dir do
    action :create
    owner node['vertica']['dbadmin_user']
    group node['vertica']['dbadmin_group']
    mode '770'
    recursive true
  end
end

#Find the device the data_dir is on, if on something like lvm it will fail jobs using this, that should only be in dev
data_mount = ''
data_dev = nil
node['filesystem'].each do |dev, values|
  if node['vertica']['data_dir'].match("^#{values['mount']}")
    if values['mount'].length > data_mount.length
      data_mount = values['mount']
      data_dev = dev.split('/')[-1].gsub(/\d/, '') #This is assuming a partition name like sda1 sdb2, etc.
    end
  end
end

#Change the I/O scheduler for vertica to deadline, this does it now, it is done on boot by the
#kernel boot option "elevator=deadline" set by the system cookbook but defined in the attribute [:system][:grub][:cmdline_linux_default]
bash "set_deadline_scheduler" do
  action :run
  code "echo deadline > /sys/block/#{data_dev}/queue/scheduler"
  not_if "grep \'\\[deadline\\]\' /sys/block/#{data_dev}/queue/scheduler"
  user "root"
  ignore_failure true
end

#Set the data drive readahead to 2048, this doesn't happen on boot but will after the first chef run
bash "set_readahead" do
  action :run
  code "blockdev --setra 2048 /dev/#{data_dev}"
  not_if "blockdev --getra /dev/#{data_dev}| grep 2048"
  user "root"
  ignore_failure true
end

# TODO: Add checks on size and verifying the data dir is its own device and decently sized

