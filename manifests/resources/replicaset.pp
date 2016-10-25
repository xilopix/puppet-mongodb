# == definition mongodb::cluster::replicaset
define mongodb::resources::replicaset (
  $master = undef,
  $slaves      = [],
) {
  # basic type validation

  validate_array($slaves)

  # server set definition

  $replica_server_set = flatten([$master, $slaves])

  # wait for replication servers starting

  start_detector { "${name}_servers_detection":
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $replica_server_set,
    policy  => all,
    tag     => ['development_replicaset']
  }

  replicaset { "$name":
    ensure  => present,
    master  => $master,
    members => $slaves,
    require => Start_detector["${name}_servers_detection"],
    tag     => ['development_replicaset']
  }
}
