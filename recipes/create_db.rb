# Lays down a db creation script and default schema

# There is a bug where $HOME is not set currectly for exec, I use sudo to avoid this
# https://tickets.opscode.com/browse/CHEF-2288
bash 'create_mon_db' do
  action :nothing
  user 'root'
  code <<-EOH
  ulimit -n 65536  # The max files open limit must be set for db creation to work.
  sudo -Hu dbadmin /var/vertica/create_mon_db.sh
  EOH
end

%w[ mon_grants.sql mon_schema.sql mon_metrics_schema.sql mon_users.sql ].each do |filename|
  cookbook_file "/var/vertica/#{filename}" do
    action :create
    source filename
    owner node[:vertica][:dbadmin_user]
    group node[:vertica][:dbadmin_group]
    mode "644"
  end
end

cookbook_file '/var/vertica/create_mon_db.sh' do
  action :create
  source 'create_mon_db.sh'
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode "755"
  notifies :run, "bash[create_mon_db]"
end

