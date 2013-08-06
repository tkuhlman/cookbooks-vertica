node.default['vertica']['monitoring_dsn'] = 'DSN=monitor'

# Setup logs for ossec to watch
node.default[:ossec][:watched][:vertica] = {
  '/opt/vertica/log/adminTools-dbadmin.log' => :syslog,
  '/var/vertica/catalog/som/v_som_node*_catalog/vertica.log' => :syslog
}
