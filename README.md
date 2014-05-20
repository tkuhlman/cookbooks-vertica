#Description

Sets up a Vertica node either standalone or as part of a cluster. This handles initial setup of the cluster and basic config.
Vertica is setup such that much of the config is done on an individual database, additionally what config is done
is typically done with their admin tools. Only changes to the cluster itself such as adding/removing a node, new network, etc
need to be made in the data bags for a cluster. As a result the cookbook is setup in most cases to ignore future changes
to tracked files and to not track many of the files created by Vertica during database setup. Additionally there is
nothing that triggers a service restart.

All entries into this cookbook should be via the default or console recipe, others are for organization only.

To run as cluster the nodes data bag item must exist otherwise it will come up stand alone.

##Cluster Assumptions:
  - The nodes are dual homed with eth1 being the cluster interface. Proper UFW setup depends on this.
  - The nodes have at two disks setup.
    - The first will include the OS and catalog and is expected to be setup on OS install.
    - The second is defined in an attribute and will be setup by chef for use as the data directory.
  - Though Chef is capable of automatically discovering which nodes belong to a cluster setting up vertica to behave
    properly in a situation of adding/removing nodes is not trivial. Additionally given the hardware requirements of
    vertica this is very unlikely so I have stuck with the simpler setup of specifying nodes in a data bag and assuming
    all nodes have the Vertica-Node role applied.
  - The backup template currently assumes 5 nodes though it could be modified to be more flexible.
  - If chef solo is being used a number of assumptions are made including:
    - Vertica Community edition is being used, ie no license
    - Insecure ssl certs are used.
    - No backup is done

###Required setup:
  - data bag items in the vertica data bag that are specific to both the cluster and location.
    - All of these follow the pattern `<databag item name><cluster name>_<location specifier>`
    - nodes - lists nodes in the cluster and the secondary interface settings
    - license - A data bag the license key, without this it will come up unlicensed
    - agent_ssl - A data bag the agent public and private keys, without this it will come up with a generic self signed cert
    - server_ssl - A data bag the server public and private keys, without this it will come up with a generic self signed cert
    - ssh_key - A data bag with a public/private ssh key pair used for setting up the dbadmin user with ssh access between nodes

###Optional Setup:
  - define the `node[:vertica][:cluster_interface]` to setup a network interface for cluster communication
  - If the ossec cookbook is available ossec rules are loaded
  - If the vertica_client::python recipe is in the run list monitoring can be setup
  - The backup scripts are not installed for chef-solo
  - Add the management console to a box by running the console recipe. It serves https on port 5450
  - The kernel params for the deadline IO scheduler will be set if the system cookbook is included otherwise a different mechanism should be pursued.

#Attributes
  - cluster_name is set to an empty string by default if you wish more than one cluster per AZ this attribute can be set for additional clusters.
  - See the file attributes/default.rb for other available attributes

#Data Bags
  - Each cluster must have a nodes data bag which should contain a nodes attribute which is a hash where the key is
    the fqdn and the value the network information for the secondary interface. If the secondary interfaces are in different
    vlans route information must be provided.
