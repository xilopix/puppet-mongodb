define mongodb::cluster::shard (
  $shard_name = $name,
  $shard_replset = undef,
  $shard_nodes = [],
) {
  # basic type validation

  validate_string($shard_replset)
  validate_array($shard_nodes)

  # wait for replica servers starting

  start_detector { "${shard_name}_servers_detection":
    ensure => present,
    timeout => 120,
    servers => $shard_nodes,
    policy => all
  }

  shard { "${shard_name}_setup":
    ensure => present,
    replica => $shard_replset,
    members => $shard_nodes,
    require => Start_detector["${shard_name}_servers_detection"]
  }
}
