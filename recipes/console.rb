# For chef solo it is assumed there is not setup apt repo with the vertica packages but rather they are in /vagrant
if Chef::Config[:solo]
  dpkg_package 'vertica-console' do
    action :install
    source "/vagrant/vertica-console_#{node[:vertica][:version]}_amd64.deb"
    version node[:vertica][:version]
  end
else
  package 'vertica-console' do
    action :install
    version node[:vertica][:version]
  end
end
