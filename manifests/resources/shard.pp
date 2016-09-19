define mongodb::resources::shard (
  $shard_name = $name,
  $shard_replicaset = undef,
  $shard_router = undef,
  $shard_nodes = [],
) {
  # basic type validation

  validate_string($shard_replicaset)
  validate_array($shard_nodes)

  # wait for replica servers starting

  start_detector { "${shard_name}_servers_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $shard_nodes,
    policy  => all
  }

  start_detector { "${shard_name}_router_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $shard_router,
    policy  => all,
    require => Start_detector["${shard_name}_servers_detection"]
  }

  shard { "${shard_name}_setup":
    ensure     => present,
    replicaset => $shard_replicaset,
    router     => $shard_router,
    nodes      => $shard_nodes,
    require => Start_detector["${shard_name}_router_detection"]
  }
}
