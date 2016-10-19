# == definition mongodb::mongos
define mongodb::resources::mongos (
  $config_servers,
  $server           = $name,
  $bind_ip          = '',
  $port             = 27017,
  $service_manage   = true,
  $enable           = true,
  $running          = true,
  $logappend        = true,
  $fork             = true,
  $useauth          = false,
  $starttime        = 1,
  $add_options      = []
) {

# lint:ignore:selector_inside_resource  would not add much to readability

  #
  # various paths
  #
  $dbdir       = $::mongodb::dbdir
  $logdir      = $::mongodb::logdir
  $conf_dir    = $::mongodb::conf_dir
  $pidfile_dir = $::mongodb::pidfilepath

  $config_servers_str = join($config_servers, ",")

  File {
    owner   => $::mongodb::run_as_user,
    group   => $::mongodb::run_as_group,
  }

  file {
    "${conf_dir}/mongos_${server}.conf":
      content => template('mongodb/mongos.conf.erb'),
      mode    => '0644',
      before  => Anchor['mongodb::mongos::end'],
      require => Class['mongodb::install'];
    "/etc/init.d/mongos_${server}":
      content => template("mongodb/mongos_init/${::osfamily}/init.conf.erb"),
      mode    => '0755',
      before  => Anchor['mongodb::mongos::end'],
      require => Class['mongodb::install'];
  }

  if ($::osfamily == 'Debian' and $::operatingsystemmajrelease == 8) {
    file { "mongos_${server}_systemd_service":
        path    => "/lib/systemd/system/mongos_${server}.service",
        content => template("mongodb/mongos_init/${::osfamily}/systemd.conf.erb"),
        mode    => '0644',
        before  => [
          Anchor['mongodb::mongos::end'],
          Exec["systemctl_${server}_reload"]
        ],
        require => [
          Class['mongodb::install'],
          File["/etc/init.d/mongos_${server}"]
        ],
    }

    # ensure daemon-reload has been done before service start

    exec { "systemctl_${server}_reload":
      command => 'systemctl daemon-reload',
      path    => '/bin',
      before  => [
        Service["mongos_${server}"],
        Anchor['mongodb::mongos::end']
      ]
    }
  }

  file { "${::mongodb::pidfilepath}/mongos_${server}":
    ensure  => directory,
    mode    => '0755',
    before  => Anchor['mongodb::mongod::end'],
    require => Class['mongodb::install'];
  }

  # wait for servers starting

  start_detector { 'config_servers':
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $config_servers_str,
    before  => Anchor['mongodb::mongos::end'],
    policy  => all
  }

  if ($useauth != false) {
    file { "/etc/mongos_${server}.key":
      content => template('mongodb/mongos.key.erb'),
      mode    => '0700',
      owner   => $::mongodb::run_as_user,
      before  => Anchor['mongodb::mongos::end'],
      require => Class['mongodb::install'],
      notify  => Service["mongos_${server}"],
    }
  }

  if ($service_manage == true) {
    service { "mongos_${server}":
      ensure     => $running,
      enable     => $enable,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::mongod_service_provider,
      before     => [
        Anchor['mongodb::mongos::end'],
        Anchor['mongodb::end']
      ],
      require    => [
        File["${conf_dir}/mongos_${server}.conf"],
        File["${::mongodb::pidfilepath}/mongos_${server}"],
        File["/etc/init.d/mongos_${server}"],
        Start_detector['config_servers'],
        Service[$::mongodb::old_servicename]
      ]
    }
  }
}
