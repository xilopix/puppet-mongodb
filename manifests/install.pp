# == Class: mongodb::install
#
#
class mongodb::install (
  $repo_manage    = true,
  $package_version = undef
) {

    # define ordering
    Class['mongodb::repos::apt']
    -> Class['apt::update']
    -> Package<| title == 'logrotate' |>
    -> Package<| title == 'mongodb-org' |>

    anchor { 'mongodb::install::begin': }
    anchor { 'mongodb::install::end': }

    if ($repo_manage == true) {
        include $::mongodb::params::repo_class
        $mongodb_10gen_package_require = [
          Anchor['mongodb::install::begin'],
          Class[$::mongodb::params::repo_class]
        ]
    } else {
        $mongodb_10gen_package_require = [
          Anchor['mongodb::install::begin']
        ]
    }

    if ($package_version == undef ) {
      $package_ensure = $::mongodb::package_ensure
    } else {
      $package_ensure = $::osfamily ? {
        redhat => "${package_version}-mongodb_1",
        debian => $package_version,
      }
    }

    package { 'mongodb-stable':
        ensure  => absent,
        name    => $::mongodb::params::old_server_pkg_name,
        require => Anchor['mongodb::install::begin'],
        before  => Anchor['mongodb::install::end']
    }

    package { 'mongodb-package':
        ensure  => $package_ensure,
        name    => $::mongodb::repos::apt::package_name,
        require => $mongodb_10gen_package_require,
        before  => [Anchor['mongodb::install::end']]
    }
}
