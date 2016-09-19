# == Class: mongodb::db
#
# Class for creating mongodb databases and users.
#
# == Parameters
#
#  user - Database username.
#  db_name - Database name. Defaults to $name.
#  server - The server from which we should take the configuration
#  password_hash - Hashed password. Hex encoded md5 hash of "$username:mongo:$password".
#  password - Plain text user password. This is UNSAFE, use 'password_hash' unstead.
#  roles (default: ['dbAdmin']) - array with user roles.
#  tries (default: 10) - The maximum amount of two second tries to wait MongoDB startup.
#
define mongodb::resources::user (
  $password      = false,
  $password_hash = false,
  $server        = '',
  $database      = $name,
  $auth          = true,
  $roles         = ['dbAdmin'],
) {
  $user = $name

  if $password {
    $hash = mongodb_password($user, $password)
  } else {
    fail("Parameter 'password' should be provided to mongodb::db.")
  }

  #
  # client connection configuration
  #
  $client_hash = {
    server       => $server,
    created_file => "${mongodb::created_file_path}/mongod_${server}/db_is_created",
    db           => getparam(Mongodb::Resources::Mongod[$server], 'admin_db'),
    username     => getparam(Mongodb::Resources::Mongod[$server], 'admin_username'),
    password     => getparam(Mongodb::Resources::Mongod[$server], 'admin_password')
  }

  mongodb_user { $name:
    ensure        => present,
    password_hash => $hash,
    database      => $database,
    client_hash   => $client_hash,
    roles         => $roles
  }
}
