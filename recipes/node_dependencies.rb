# System configuration needed or desired before Vertica setup
#
# UFW setup is handled by the attributes in ufw.rb

# A few packages recommended for use with vertica,  bc and ssh are actual requirements that should
# be taken care of by apt but when running vertica's install script it uses dpkg so I set them up.
%w[ logrotate pstack rsync bc ssh ].each do |pkg_name|
  package pkg_name do
    action :install
  end
end


##Sysctl and security settings
sysctl 'vm.min_free_kbytes' do
  action :set
  value '4096'
end
sysctl 'vm.max_map_count' do 
  action :set
  value (node[:memory][:total].to_i/16).to_s #ram in KB/16
end

# Setup User limits for the db
template '/etc/security/limits.d/vertica.conf' do
  action :create
  source 'vertica_limits.erb'
  owner 'root'
  group 'root'
  mode '644'
end

# Ubuntu by default doesn't apply security limits to su sessions but admintools uses su so it is needed
bash 'su_pam_limits' do
  action :run
  code 'echo -e "\n#For Vertica\nsession required pam_limits.so" >> /etc/pam.d/su'
  not_if "grep '^session\s*required\s*pam_limits.so' /etc/pam.d/su"
end

# Setup the LANG variable
file '/etc/profile.d/vertica_lang.sh' do
  action :create
  owner 'root'
  group 'root'
  mode "644"
  content 'export LANG="en_US.UTF-8"'
end
