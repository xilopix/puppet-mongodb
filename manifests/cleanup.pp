# == Class: mongodb::cleanup
#
# Uninstall mongod instance which was installed by package manager
#
#
class mongodb::cleanup {
  service { 'mongod':
    ensure => stopped,
    enable => false
  }

  file {[
    '/etc/init.d/mongod',
    '/etc/init.d/mongodb',
    '/run/systemd/generator.late/mongodb.service',
    '/var/log/mongodb/mongod.log',
    '/var/run/mongod.pid',
    "/lib/systemd/system/mongod.service"
  ]:
    ensure  => absent,
    require => [
      Exec['Remove mongod by systemctl'],
      Exec['Reset units by systemctl']
    ]
  }

  exec { 'Remove mongod by systemctl':
    command => 'systemctl disable mongod.service',
    path    => ['/bin']
  }

  exec { 'Reset units by systemctl':
    command => 'systemctl reset-failed',
    path    => ['/bin'],
    require => [
      Service['mongod'],
      Exec['Remove mongod by systemctl']
    ]
  }
}
