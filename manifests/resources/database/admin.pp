#
#
#
define mongodb::resources::database::admin() {
  $server         = $name
  $admin_db       = getparam(Mongodb::Resources::Mongod[$server], 'admin_db')
  $admin_username = getparam(Mongodb::Resources::Mongod[$server], 'admin_username')
  $admin_password = getparam(Mongodb::Resources::Mongod[$server], 'admin_password')

  #
  # because a mongod should have a defined admin_db param to create admin database
  #
  if $admin_db {
    mongodb::resources::database { "admin_database_${server}":
      db_name => admin,
      server  => $server,
      tries   => 10,
      require => [
        Service["mongod_${server}"],
        Anchor['mongodb::mongod::end']
      ]
    }

    mongodb::resources::user { "${admin_username}_${server}":
      username => root,
      database => admin,
      password => $admin_password,
      server   => $server,
      roles    => ['clusterAdmin', 'root'],
      require  => [Mongodb::Resources::Database["admin_database_${server}"]]
    }

    exec { "restart_mongod_${server}":
      command => "/bin/systemctl restart mongod_${server}",
      require => [Mongodb::Resources::User["${admin_username}_${server}"]]
    }

    file { "admin_db_created_${server}":
      ensure  => present,
      path    => "${mongodb::created_file_path}/mongod_${server}/db_is_created",
      require => [Exec["restart_mongod_${server}"]]
    }
  }
}