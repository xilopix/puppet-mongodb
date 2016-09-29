# == definition mongodb::mongos
define mongodb::resources::mongos (
  $config_servers,
  $instance         = $name,
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


  $config_servers_str = join($config_servers, ",")

  file {
    "/etc/mongos_${instance}.conf":
      content => template('mongodb/mongos.conf.erb'),
      mode    => '0755',
      require => Class['mongodb::install'];
    "/etc/init.d/mongos_${instance}":
      content => template("mongodb/mongos_init/${::osfamily}/init.conf.erb"),
      mode    => '0755',
      require => Class['mongodb::install'];
  }

  if ($::osfamily == 'Debian' and $::operatingsystemmajrelease == 8) {
    file { "mongos_${instance}_systemd_service":
        path    => "/lib/systemd/system/mongos_${instance}.service",
        content => template("mongodb/mongos_init/${::osfamily}/systemd.conf.erb"),
        mode    => '0644',
        before  => Exec["systemctl_${instance}_reload"],
        require => [
          Class['mongodb::install'],
          File["/etc/init.d/mongos_${instance}"]
        ],
    }

    # ensure daemon-reload has been done before service start

    exec { "systemctl_${instance}_reload":
      command => 'systemctl daemon-reload',
      path    => '/bin',
      before  => Service["mongos_${instance}"],
    }
  }

  # wait for servers starting

  start_detector { 'config_servers':
    ensure  => present,
    timeout => $mongodb::detector_timeout,
    servers => $config_servers_str,
    policy  => all
  }

  if ($useauth != false) {
    file { "/etc/mongos_${instance}.key":
      content => template('mongodb/mongos.key.erb'),
      mode    => '0700',
      owner   => $::mongodb::run_as_user,
      require => Class['mongodb::install'],
      notify  => Service["mongos_${instance}"],
    }
  }

  if ($service_manage == true) {
    service { "mongos_${instance}":
      ensure     => $running,
      enable     => $enable,
      hasstatus  => true,
      hasrestart => true,
      provider   => $::mongod_service_provider,
      before     => Anchor['mongodb::end'],
      require    => [
        File["/etc/mongos_${instance}.conf"],
        File["/etc/init.d/mongos_${instance}"],
        Start_detector['config_servers'],
        Service[$::mongodb::old_servicename]
      ]
    }
  }
}
