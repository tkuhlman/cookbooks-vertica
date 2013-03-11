# Add users and groups needed for a node
# This recipe should not stand alone but be included from another

user node['vertica']['spread_user'] do
  action :create
  system  true
end

# I setup ssh_key login for the dbadmin user but no password auth
user node['vertica']['dbadmin_user'] do
  action :create
  shell "/bin/bash" #dash causes issues with some vertica scripts.
end

# Setup the private ssh key for the dbadmin user. The authorized_keys part is setup by the openssh cookbook via the ssh_keys data bag
directory "#{node['vertica']['dbadmin_home']}/.ssh" do
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_user']
  mode "700"
  recursive true #Old versions of chef aren't creating the home dir even with manage_home set to true
end

file "#{node['vertica']['dbadmin_home']}/.ssh/config" do #Turn off strict host key checking so it works without manual intervention
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_user']
  mode "600"
  content "StrictHostKeyChecking no"
end

#Pull the ssh_key from the edb leveraging normalize to make sure it exists as a string.
#Note: That though this can be different by location, the openssh data bag which sets up the authorized keys does not
#yet support the get_data_bag_* functions so a shared key is used for all environments
ssh_key = normalize(get_data_bag_item("vertica", "ssh_key", { :encrypted => true}), {
  :key => { :required => true, :typeof => String }
})['key']

file "#{node['vertica']['dbadmin_home']}/.ssh/id_rsa" do #The private ssh_key
  action :create
  owner node['vertica']['dbadmin_user']
  group node['vertica']['dbadmin_user']
  mode "600"
  content ssh_key
end

#The verticadba group is setup for public key auth, via the standard auth mechanism, ie authorised_groups attribute and ssh data bag
#though note that the group must exist first so the first run makes the group the 2nd sets up the authorized_keys file.
group node['vertica']['dbadmin_group'] do
  action :create
  members node['vertica']['dbadmin_user']
end


#Setup user based config in vertica
directory "/opt/vertica/config/users/#{node['vertica']['dbadmin_user']}" do
  action :create
  owner node['vertica']['dbadmin_user']
  group 'root'
  mode "775"
  recursive true
end

file "/opt/vertica/config/users/#{node['vertica']['dbadmin_user']}/agent.conf" do
  action :create_if_missing
  owner 'root'
  group 'root'
  mode "664"
end

cookbook_file "/opt/vertica/config/users/#{node['vertica']['dbadmin_user']}/installed.dat" do
  action :create_if_missing
  source "installed.dat"
  owner node['vertica']['dbadmin_user']
  group 'root'
  mode "775"
end

# The startup script for the vertica agent has a bug where it starts as the dbadmin user but with its home set to /root
# It then fails in a script and is unable to pump some data to the mc, the work around is to make /root readable by dbadmin
directory "/root" do
  action :create
  owner 'root'
  group 'root'
  mode "775"
end
