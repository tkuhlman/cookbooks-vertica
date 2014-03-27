package 'vertica-console' do
  action :install
  version node[:vertica][:version]
end
