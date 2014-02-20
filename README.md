#Description

Sets up a Vertica node either standalone or as part of a cluster. This handles initial setup of the cluster and basic config.
Vertica is setup such that much of the config is done on an individual database, additionally what config is done
is typically done with their admin tools. Only changes to the cluster itself such as adding/removing a node, new network, etc
need to be made in the data bags for a cluster. As a result the cookbook is setup in most cases to ignore future changes
to tracked files and to not track many of the files created by Vertica during database setup. Additionally there is
nothing that triggers a service restart.

All entries into this cookbook should be via the default recipe, others are for organization only.

To run as cluster the nodes data bag item must exist otherwise it will come up stand alone.

##Cluster Assumptions:
  - The nodes are dual homed with eth1 being the cluster interface. Proper UFW setup depends on this.
  - The nodes have at two disks setup.
    - The first will include the OS and catalog and is expected to be setup on OS install.
    - The second is defined in an attribute and will be setup by chef for use as the data directory.
  - This cookbook is written in a way that is quite specific to HP Cloud, relying on various features/setup of basenode, including:
    - hpcloud system cookbook which defines kernel boot params used by grub
    - hpcloud auth setup to allow passwordless ssh for the dbadmin user
  - This cookbook will be called via the Vertica-Node role which includes some essential attributes
  - Though Chef is capable of automatically discovering which nodes belong to a cluster setting up vertica to behave
    properly in a situation of adding/removing nodes is not trivial. Additionally given the hardware requirements of
    vertica this is very unlikely so I have stuck with the simpler setup of specifying nodes in a data bag and assuming
    all nodes have the Vertica-Node role applied.
  - The backup template currently assumes 5 nodes though it could be modified to be more flexible.

##Required setup:
  - data bag items in the vertica data bag that are specific to both the cluster and location.
    - All of these follow the pattern `<databag item name><cluster name>_<location specifier>`
    - nodes - lists nodes in the cluster and the secondary interface settings
    - license - An edb with the license key, without this it will come up unlicensed
    - agent_ssl - An edb with the agent public and private keys, without this it will come up with a generic self signed cert
    - agent_ssl - An edb with the server public and private keys, without this it will come up with a generic self signed cert
  - Ssh setup for the dbadmin user, including:
    - ssh databag for the dbadmin_group
    - ssh_keys data bag for the dbadmin user
    - ssh_key edb in the vertica data bag

##Optional Setup:
  - If the ossec cookbook is available ossec rules are loaded
  - If the vertica_client::python recipe is in the run list monitoring can be setup
  - The backup scripts are not installed for chef-solo

#Attributes
  - cluster_name is set to an empty string by default if you wish more than one cluster per AZ this attribute can be set for additional clusters.
  - See the file attributes/default.rb for other available attributes

#Data Bags
All of the below data bags can be split by location according to the get_data* functions which are part of hp_common_functions unless running in chef_solo
  - Each cluster must have a nodes data bag which should contain a nodes attribute which is a hash where the key is
    the fqdn and the value the network information for the secondary interface. If the secondary interfaces are in different
    vlans route information must be provided.

# Future Considerations
  - This cookbook was originally setup for the HPCS environment and includes various bits specific to that env still.
    In the future should these be completely removed?
    - hp_common_functions usages of normalize and get_data* functions
    - The entire ssh key setup in recipes/node_users
    - system cookbook that sets grub boot params
