#
#
#
define mongodb::resources::database::applicative(
  $db_name = false,
  $server  = false,
  $tries   = 10
) {
  mongodb::resources::database { $name:
    db_name => $db_name,
    server  => $server,
    tries   => 10,
    require => [
      Service["mongod_${server}"],
      Anchor['mongodb::mongod::end']
    ]
  }
}