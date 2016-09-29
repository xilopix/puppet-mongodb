define mongodb::resources::shard (
  $replicaset = undef,
  $router = undef,
  $nodes = [],
) {
  # basic type validation

  validate_string($replicaset)
  validate_array($nodes)

  # wait for replica servers starting

  start_detector { "${shard_name}_servers_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $nodes,
    policy  => all
  }

  start_detector { "${shard_name}_router_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $router,
    policy  => all,
    require => Start_detector["${shard_name}_servers_detection"]
  }

  shard { "${shard_name}_setup":
    ensure     => present,
    replicaset => $replicaset,
    router     => $router,
    nodes      => $nodes,
    require => Start_detector["${shard_name}_router_detection"]
  }
}