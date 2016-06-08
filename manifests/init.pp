# == Class: mediawiki
#
# Full description of class mediawiki here.
#
# === Parameters
#
# Document parameters here.
#
# [*sample_parameter*]
#   Explanation of what this parameter affects and what it defaults to.
#   e.g. "Specify one or more upstream ntp servers as an array."
#
# === Variables
#
# Here you should define a list of variables that this module would require.
#
# [*sample_variable*]
#   Explanation of how this variable affects the funtion of this class and if
#   it has a default. e.g. "The parameter enc_ntp_servers must be set by the
#   External Node Classifier as a comma separated list of hostnames." (Note,
#   global variables should be avoided in favor of class parameters as
#   of Puppet 2.6.)
#
# === Examples
#
#  class { 'mediawiki':
#    servers => [ 'pool.ntp.org', 'ntp.local.company.com' ],
#  }
#
# === Authors
#
# Author Name <author@domain.com>
#
# === Copyright
#
# Copyright 2016 Your name here, unless otherwise noted.
#
class mediawiki {
  $packages = [
    'mediawiki',
    'mediawiki-extensions',
    'imagemagick',
  ]

  package {$packages:
    ensure => latest,
  }

  $config_meta = '/etc/mediawiki/LocalSettings.php'
  concat {$config_meta:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    require => Package['mediawiki'],
  }

  concat::fragment {'mediawiki_config_meta_header':
    target => $config_meta,
    source => 'puppet:///modules/mediawiki/config_meta_header',
    order  => '00',
  }
  concat::fragment {'mediawiki_config_meta_footer':
    target => $config_meta,
    source => 'puppet:///modules/mediawiki/config_meta_footer',
    order  => '99',
  }
}
