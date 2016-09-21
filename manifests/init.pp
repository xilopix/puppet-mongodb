# == Class: mongodb
#
class mongodb (
  $dbdir                    = $mongodb::params::dbdir,
  $conf_dir                 = $mongodb::params::conf_dir,
  $pidfilepath              = $mongodb::params::pidfilepath,
  $logdir                   = $mongodb::params::logdir,
  $logrotatenumber          = $mongodb::params::logrotatenumber,
  $logrotate_package_manage = $mongodb::params::logrotate_package_manage,
  $package_ensure           = $mongodb::params::package_ensure,
  $package_name             = $mongodb::params::mongodb_pkg_name,
  $repo_manage              = $mongodb::params::repo_manage,
  $ulimit_nofiles           = $mongodb::params::ulimit_nofiles,
  $ulimit_nproc             = $mongodb::params::ulimit_nproc,
  $run_as_user              = $mongodb::params::run_as_user,
  $run_as_group             = $mongodb::params::run_as_group,
  $old_servicename          = $mongodb::params::old_servicename,
  $detector_timeout         = $mongodb::params::detector_timeout,
  $created_file_path        = $mongodb::params::created_file_path,

  ### START Hiera Lookups ###
  $databases  = hiera_hash('mongodb::databases', {}),
  $users      = hiera_hash('mongodb::users', {}),
  $collection = hiera_hash('mongodb::collection', {}),
  $mongod     = hiera_hash('mongodb::mongod', {}),
  $mongos     = hiera_hash('mongodb::mongos', {}),
  $replicaset = hiera_hash('mongodb::replicaset', {}),
  $shard      = hiera_hash('mongodb::shard', {}),
  ### END Hiera Lookups ###
) inherits mongodb::params {

  anchor { 'mongodb::begin': before => Anchor['mongodb::install::begin'], }
  anchor { 'mongodb::end': }

  #
  # allow ordering between resources in same defined resource mongodb::mongod
  #
  anchor { 'mongodb::mongod::begin': }
  anchor { 'mongodb::mongod::end': }

  case $::osfamily {
    /(?i)(Debian|RedHat)/ : {
      class { 'mongodb::install': repo_manage => $repo_manage }
    }
    default               : {
      fail "Unsupported OS ${::operatingsystem} in 'mongodb' module"
    }
  }

  class { 'mongodb::logrotate':
    require => Anchor['mongodb::install::end'],
    before  => Anchor['mongodb::end'],
  }

  #
  # stop and disable default mongod
  #
  service { $::mongodb::old_servicename:
    ensure     => stopped,
    enable     => false,
    hasstatus  => true,
    hasrestart => true,
    subscribe  => Package['mongodb-package'],
    before     => Anchor['mongodb::end'],
  }

  mongodb::limits::conf {
    'mongod-nofile-soft':
      type  => soft,
      item  => nofile,
      value => $::mongodb::ulimit_nofiles;

    'mongod-nofile-hard':
      type  => hard,
      item  => nofile,
      value => $::mongodb::ulimit_nofiles;

    'mongod-nproc-soft':
      type  => soft,
      item  => nproc,
      value => $::mongodb::ulimit_nproc;

    'mongod-nproc-hard':
      type  => hard,
      item  => nproc,
      value => $::mongodb::ulimit_nproc;
  }

  #
  # add virtual admin databases resources for mongod servers
  #
  $servers = keys($mongod)
  mongodb::resources::database::admin { $servers: }

  #
  # to ensure admin db and user are created before others
  #
  Mongodb::Resources::Database::Admin <| |>
  -> Mongodb::Resources::Database::Applicative <| |>

  #
  # ensure admin user is created after admin database
  #
  Mongodb::Resources::User <| tag == 'admin' |>
  -> Mongodb::Resources::Database::Applicative <| |>
  -> Mongodb::Resources::User <| tag == 'no_admin' |>

  #
  # to avoid launching detector before mongod servers installation
  #
  Mongodb::Resources::Mongod <| |>
  -> Start_detector <| |>

  #
  # global orderings
  #
  Mongodb::Resources::Mongod <| |>
  -> Mongodb::Resources::Replicaset <| |>
  -> Mongodb::Resources::Database <| |>
  -> Mongodb::Resources::Mongos <| |>
  -> Mongodb::Resources::Shard <| |>

  #
  # handle resources for hiera
  #
  create_resources('mongodb::resources::mongod', $mongod)
  create_resources('mongodb::resources::database::applicative', $databases)
  create_resources('mongodb::resources::user', $users)
  create_resources('mongodb::resources::mongos', $mongos)
  create_resources('mongodb::resources::replicaset', $replicaset)
  create_resources('mongodb::resources::shard', $shard)
}
