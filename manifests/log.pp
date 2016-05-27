# Class: mongodb::log
#
# This module manages mongodb services.
# It provides the functions for mongod and mongos instances.
#
class mongodb::log (
  $mongod_logdir   = $::mongodb::logdir
){
  file { "${mongod_logdir}":
    ensure  => directory,
    mode    => '0755',
    owner  => $::mongodb::run_as_user,
    group  => $::mongodb::run_as_group,
    require => [Package['mongodb-package']],
  }
}
