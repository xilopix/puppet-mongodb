define mongodb::resources::shard (
  $replicaset = undef,
  $router = undef,
  $nodes = [],
) {
  # basic type validation

  validate_string($replicaset)
  validate_array($nodes)

  # wait for replica servers starting

  start_detector { "${name}_servers_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $nodes,
    policy  => all,
    tag     => ['development_shard']
  }

  start_detector { "${name}_router_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $router,
    policy  => all,
    require => Start_detector["${name}_servers_detection"],
    tag     => ['development_shard']
  }

  shard { "${name}_setup":
    ensure     => present,
    replicaset => $replicaset,
    router     => $router,
    nodes      => $nodes,
    require    => Start_detector["${name}_router_detection"],
    tag        => ['development_shard']
  }
}
