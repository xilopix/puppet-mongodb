# == definition mongodb::cluster::replicaset
define mongodb::cluster::replicaset (
  $replicaset_name        = $name,
  $replicaset_master_port = undef,
  $replicaset_slaves      = [],
  $replicaset_router      = undef,
) {
  # basic type validation

  validate_numeric($replicaset_master_port)
  validate_array($replicaset_slaves)

  # server set definition

  $replicaset_master = "${::fqdn}:${replicaset_master_port}"
  $replica_server_set = flatten([$replicaset_master, $replicaset_slaves])

  # wait for shard servers starting

  start_detector { "${replicaset_name}_servers_detection":
    ensure => present,
    timeout => 120,
    servers => $replica_server_set,
    policy => all
  }

  replicaset { "$replicaset_name":
    ensure => present,
    router => $replicaset_router,
    members => $replica_server_set,
    require => Start_detector["${replicaset_name}_servers_detection"]
  }
}
