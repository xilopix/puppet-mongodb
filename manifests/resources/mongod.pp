# == definition mongodb::mongod
define mongodb::resources::mongod (
  $server                          = $name,
  $bind_ip                         = '',
  $port                            = 27017,
  $replicaset                      = '',
  $enable                          = true,
  $running                         = true,
  $configsvr                       = false,
  $shardsvr                        = false,
  $logappend                       = true,
  $rest                            = true,
  $fork                            = true,
  $auth                            = false,
  $useauth                         = false,
  $monit                           = false,
  $engine                          = 'wiredTiger',
  $add_options                     = [],
  $deactivate_transparent_hugepage = false,
  $admin_db                        = false,
  $admin_username                  = '',
  $admin_password                  = '',
  $configuration                   = {},
  $databases                       = {}
) {

# lint:ignore:selector_inside_resource  would not add much to readability

  if (versioncmp($mongodb::package_ensure, '3.0.0') >= 0) {
    $template_type = 'yaml'
  } else {
    $template_type = 'ini'
  }

  $dbdir    = $::mongodb::dbdir
  $logdir   = $::mongodb::logdir
  $conf_dir = $::mongodb::conf_dir


  #
  # set db dir path
  #
  $db_dir_path = xi_get_file_directory_tree($dbdir)

  ensure_resource('file', $db_dir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::mongod::end'],
    'require' => Class['mongodb::install']
  })

  #
  # set log dir path
  #
  $logdir_path = xi_get_file_directory_tree($logdir)

  ensure_resource('file', $logdir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::mongod::end'],
    'require' => Class['mongodb::install']
  })

  #
  # set conf dir path
  #
  $conf_dir_path = xi_get_file_directory_tree($conf_dir)

  ensure_resource('file', $conf_dir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::mongod::end'],
    'require' => Class['mongodb::install']
  })

  file { "${::mongodb::conf_dir}/mongod_${server}.conf":
    content => template("mongodb/mongod_conf/$template_type.conf.erb"),
    mode    => '0755',
    before  => Anchor['mongodb::mongod::end'],
    require => Class['mongodb::install'];
  }

  file { "${::mongodb::pidfilepath}/mongod_${server}":
    ensure  => directory,
    mode    => '0755',
    before  => Anchor['mongodb::mongod::end'],
    require => Class['mongodb::install'];
  }

  exec { "copy_${server}_conf_to_yaml":
    command => "cp ${::mongodb::conf_dir}/mongod_${server}.conf /tmp/mongod_${server}.yaml",
    path    => ['/bin'],
    before  => Anchor['mongodb::mongod::end'],
    require => [File["${::mongodb::conf_dir}/mongod_${server}.conf"]]
  }

  set_configuration { "configure_mongod_${server}":
    ensure    => present,
    input     => "/tmp/mongod_${server}.yaml",
    configure => { replace => $configuration },
    before  => Anchor['mongodb::mongod::end'],
    require   => [
      File["${::mongodb::conf_dir}/mongod_${server}.conf"],
      Exec["copy_${server}_conf_to_yaml"]
    ]
  }

  exec { "copy_${server}_conf_to_conf":
    command => "cp /tmp/mongod_${server}.yaml ${::mongodb::conf_dir}/mongod_${server}.conf",
    path    => ['/bin'],
    before  => Anchor['mongodb::mongod::end'],
    require => [Set_configuration["configure_mongod_${server}"]]
  }

  if ($::osfamily == 'Debian' and $::operatingsystemmajrelease == 8) {
    $init_file_path = "/lib/systemd/system/mongod_${server}.service"
    file { "${init_file_path}":
        path => "/lib/systemd/system/mongod_${server}.service",
        content => template("mongodb/mongod_init/${::osfamily}/systemd.conf.erb"),
        mode    => '0644',
        before  => [
          Anchor['mongodb::mongod::end'],
          Exec["systemctl_${server}_reload"]
        ],
        require => [
          Class['mongodb::install'],
          File["${::mongodb::conf_dir}/mongod_${server}.conf"]
      ];
    }
  } else {
    $init_file_path = "/etc/init.d/mongod_${server}"
    file { "${init_file_path}":
      content => template("mongodb/mongod_init/${::osfamily}/init.conf.erb"),
      mode    => '0755',
      before  => Anchor['mongodb::mongod::end'],
      require => [
        Class['mongodb::install'],
        File["/etc/mongod_${server}.conf"]
      ]
    }
  }

  # ensure daemon-reload has been done before service start

  exec { "systemctl_${server}_reload":
    command => 'systemctl daemon-reload',
    path    => '/bin',
    before  => [
      Anchor['mongodb::mongod::end'],
      Service["mongod_${server}"]
    ]
  }

# lint:endignore

  if ($monit != false) {
    # notify { "mongod_monit is : ${monit}": }
    class { 'mongodb::monit':
      server_name => $server,
      server_port => $port,
      require       => Anchor['mongodb::install::end'],
      before  => [
        Anchor['mongodb::end'],
        Anchor['mongodb::mongod::end'],
        Service["mongod_${server}"]
      ]
    }
  }

  if ($useauth != false) {
    file { "/etc/mongod_${server}.key":
      content => template('mongodb/mongod.key.erb'),
      mode    => '0700',
      owner   => $mongodb::params::run_as_user,
      before  => Anchor['mongodb::mongod::end'],
      require => Class['mongodb::install'],
      notify  => Service["mongod_${server}"],
    }
  }

  file {[
    "${::mongodb::dbdir}/mongod_${server}",
    "/var/run/mongod_${server}"
  ]:
    ensure  => directory,
    owner   => $mongodb::params::run_as_user,
    group   => $mongodb::params::run_as_group,
    before  => [
      Service["mongod_${server}"],
      Anchor['mongodb::mongod::end']
    ],
    require => Class['install']
  }

  service { "mongod_${server}":
    ensure     => $running,
    enable     => $enable,
    hasstatus  => true,
    hasrestart => true,
    provider   => $::mongod_service_provider,
    require    => [File[
        "${::mongodb::conf_dir}/mongod_${server}.conf",
        "${init_file_path}"
      ],
      Service[$::mongodb::old_servicename]
    ],
    before     => [
      Anchor['mongodb::end'],
      Anchor['mongodb::mongod::end']
    ]
  }
}
