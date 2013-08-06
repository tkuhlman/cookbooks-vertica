maintainer       "SOM Team"
maintainer_email "hpcs-mon@hp.com"
license          "All rights reserved"
description      "Installs/Configures vertica"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.18"
depends          "hostsfile"
depends          "hp_common_functions", ">= 0.13.0"
depends          "sysctl"
depends          "version_pins"
depends          "vertica_client" #needed for the monitor recipe
depends          "ossec"
