name             'vertica'
maintainer       'SOM Team'
maintainer_email 'hpcs-mon@hp.com'
license          'All rights reserved'
description      'Installs/Configures vertica'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '1.1.8'
depends          'hostsfile'
depends          'sysctl'
depends          'python'  # Used for the backup recipe
