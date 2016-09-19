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
define mongodb::resources::database (
  $db_name = false,
  $server  = false,
  $tries   = 10
) {

  if ! $db_name {
    $database_name = $name
  } else {
    $database_name = $db_name
  }

  if ! $server {
    fail('You must specify on which server the database should be set')
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

  mongodb_database { $name:
    ensure      => present,
    db_name     => $database_name,
    client_hash => $client_hash,
    tries       => $tries,
    require     => [Anchor['mongodb::mongod::end']]
  }
}
