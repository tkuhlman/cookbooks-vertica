default['vertica']['firewall']['rules'] = [
  "sql" => {
    "port" => "5433",
    "protocol" => "tcp"
  },
# Allow all communication on the nic used for internal cluster communication
  "intra-cluster" => {
    "interface" => "eth1"
  }
]
