# Add users and groups needed for a node
# This recipe should not stand alone but be included from another

# I setup ssh_key login for the dbadmin user but no password auth
user node[:vertica][:dbadmin_user] do
  action :create
  supports :manage_home => true
  home node[:vertica][:dbadmin_home]
  shell "/bin/bash" #dash causes issues with some vertica scripts.
end

# Setup the private ssh key for the dbadmin user. The authorized_keys part is setup by the openssh cookbook via the ssh_keys data bag
directory "#{node[:vertica][:dbadmin_home]}/.ssh" do
  action :create
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_user]
  mode "700"
  recursive true #Old versions of chef aren't creating the home dir even with manage_home set to true
end

file "#{node[:vertica][:dbadmin_home]}/.ssh/config" do #Turn off strict host key checking so it works without manual intervention
  action :create
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_user]
  mode "600"
  content "StrictHostKeyChecking no"
end

if node[:vertica][:cluster]
  #Pull the ssh_key from a data bag
  ssh_key = data_bag_item("vertica", "ssh_key#{node[:vertica][:cluster_name]}")

  file "#{node[:vertica][:dbadmin_home]}/.ssh/id_rsa" do #The private ssh_key
    action :create
    owner node[:vertica][:dbadmin_user]
    group node[:vertica][:dbadmin_user]
    mode "600"
    content ssh_key['private']
  end
  file "#{node[:vertica][:dbadmin_home]}/.ssh/authorized_keys" do #The public ssh_key
    action :create
    owner node[:vertica][:dbadmin_user]
    group node[:vertica][:dbadmin_user]
    mode "644"
    content ssh_key['public']
  end
else
  bash 'create ssh key' do
    action :run
    code <<-EOH
    ssh-keygen -t rsa -b 2048 -f #{node[:vertica][:dbadmin_home]}/.ssh/id_rsa -q -N '' 
    cp #{node[:vertica][:dbadmin_home]}/.ssh/id_rsa.pub #{node[:vertica][:dbadmin_home]}/.ssh/authorized_keys
    EOH
    user node[:vertica][:dbadmin_user]
    not_if do ::File.exists?("#{node[:vertica][:dbadmin_home]}/.ssh/id_rsa") end
  end
end

group node[:vertica][:dbadmin_group] do
  action :create
  members node[:vertica][:dbadmin_user]
end

#Setup user based config in vertica
directory "/opt/vertica/config/users/#{node[:vertica][:dbadmin_user]}" do
  action :create
  owner node[:vertica][:dbadmin_user]
  group 'root'
  mode "775"
  recursive true
end

file "/opt/vertica/config/users/#{node[:vertica][:dbadmin_user]}/agent.conf" do
  action :create_if_missing
  owner 'root'
  group 'root'
  mode "664"
end
