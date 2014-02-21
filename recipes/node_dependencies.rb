# System configuration needed or desired before Vertica setup
#
# UFW setup is handled by the attributes in ufw.rb

# A few packages recommended for use with vertica,  bc and ssh are actual requirements that should
# be taken care of by apt but when running vertica's install script it uses dpkg so I set them up.
%w[ logrotate pstack rsync ssh sysstat mcelog ].each do |pkg_name|
  package pkg_name do
    action :install
  end
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
file '/etc/profile.d/vertica_node.sh' do
  action :create
  owner 'root'
  group 'root'
  mode "644"
  content "export LANG='en_US.UTF-8'\nexport LC_ALL='en_US.UTF-8'\nexport R_HOME=/opt/vertica/R\n"
end
