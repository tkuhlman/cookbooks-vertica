# Lays down a db creation script and default schema

# Rather than laying down a script I could just use the bash resource, this is what I originally did but
# the db creation step does not work on the first chef run. It would work on subsequent. I never figured out
# why but rather went with the technique of laying down this script which can be run after chef.
cookbook_file '/var/vertica/create_mon_db.sh' do
  action :create
  source 'create_mon_db.sh'
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode "755"
end

cookbook_file '/var/vertica/mon_schema.sql' do
  action :create
  source 'mon_schema.sql'
  owner node[:vertica][:dbadmin_user]
  group node[:vertica][:dbadmin_group]
  mode "644"
end

