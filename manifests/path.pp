# Class: mongodb::path
#
# This module manages mongodb services.
# It provides the functions for mongod and mongos instances.
#
class mongodb::path {

  #
  # shortcut for init variables
  #
  $dbdir       = $::mongodb::dbdir
  $logdir      = $::mongodb::logdir
  $conf_dir    = $::mongodb::conf_dir
  $pidfile_dir = $::mongodb::pidfilepath

  #
  # set db dir path
  #
  $db_dir_path = xi_get_file_directory_tree($dbdir)

  ensure_resource('file', $db_dir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::end'],
    'require' => Class['mongodb::install']
  })

  #
  # set log dir path
  #
  $logdir_path = xi_get_file_directory_tree($logdir, 1)

  ensure_resource('file', $logdir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::end'],
    'require' => Class['mongodb::install']
  })

  #
  # set conf dir path
  #
  $conf_dir_path = xi_get_file_directory_tree($conf_dir, 1)

  ensure_resource('file', $conf_dir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::end'],
    'require' => Class['mongodb::install']
  })

  #
  # set pidfile dir path
  #
  $pidfile_dir_path = xi_get_file_directory_tree($pidfile_dir, 1)

  ensure_resource('file', $pidfile_dir_path, {
    'ensure'  => directory,
    'owner'   => $mongodb::params::run_as_user,
    'group'   => $mongodb::params::run_as_group,
    'before'  => Anchor['mongodb::end'],
    'require' => Class['mongodb::install']
  })
}