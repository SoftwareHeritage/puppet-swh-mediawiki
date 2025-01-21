define mediawiki::instance (
  String $vhost_name = $title,
  String $vhost_docroot = '/var/lib/mediawiki',
  String $vhost_fpm_root = 'http://127.0.0.1:5000',
  String $vhost_basic_auth = '',
  Array[String] $vhost_aliases = [],
  String $vhost_ssl_protocol = 'all -SSLv2 -SSLv3',
  String $vhost_ssl_honorcipherorder = 'On',
  String $vhost_ssl_cipher = 'EDH+CAMELLIA:EDH+aRSA:EECDH+aRSA+AESGCM:EECDH+aRSA+SHA384:EECDH+aRSA+SHA256:EECDH:+CAMELLIA256:+AES256:+CAMELLIA128:+AES128:+SSLv3:!aNULL:!eNULL:!LOW:!3DES:!MD5:!EXP:!PSK:!DSS:!RC4:!SEED:!ECDSA:CAMELLIA256-SHA:AES256-SHA:CAMELLIA128-SHA:AES128-SHA',
  String $vhost_ssl_cert = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  String $vhost_ssl_chain = '/etc/ssl/certs/ssl-cert-snakeoil.pem',
  String $vhost_ssl_key = '/etc/ssl/private/ssl-cert-snakeoil.key',
  String $vhost_ssl_hsts_header = 'add Strict-Transport-Security "max-age=15768000"',
  String $db_user = 'mediawiki',
  String $db_basename = 'mediawiki',
  String $db_host = 'localhost',
  String $db_password = 'verysecret',
  String $secret_key = 'secretkey',
  String $upgrade_key = 'upgradekey',
  String $swh_logo = '/images/b/b2/Swh-logo.png',
  String $site_name = 'MediaWiki',
  ){
    include ::mediawiki

    $vhost_basic_auth_file = "/etc/apache2/mediawiki_${vhost_name}_http_auth"
    $config_relative = "LocalSettings_${vhost_name}.php"
    $config = "/etc/mediawiki/${config_relative}"

    include ::mysql::client

    ::mysql::db {$db_basename:
      user     => $db_user,
      password => $db_password,
      host     => $db_host,
      grant    => ['ALL'],
    }

    include ::apache
    include ::apache::mod::proxy
    include ::profile::apache::mod_proxy_fcgi

  ::apache::vhost {"${vhost_name}_non-ssl":
    servername      => $vhost_name,
    serveraliases   => $vhost_aliases,
    port            => 80,
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  if $vhost_basic_auth != '' {
    file {$vhost_basic_auth_file:
      ensure  => present,
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      content => $vhost_basic_auth,
    }
    $root_directory = {
      path           => '/',
      provider       => 'location',
      auth_type      => 'Basic',
      auth_name      => 'Software Heritage development',
      auth_user_file => $vhost_basic_auth_file,
      auth_require   => 'valid-user',
    }
  }
  else {
    file {$vhost_basic_auth_file:
      ensure => absent,
    }
    $root_directory = {}
  }

  ::apache::vhost {"${vhost_name}_ssl":
    servername           => $vhost_name,
    serveraliases        => $vhost_aliases,
    port                 => 443,
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $vhost_ssl_cert,
    ssl_chain            => $vhost_ssl_chain,
    ssl_key              => $vhost_ssl_key,
    headers              => [$vhost_ssl_hsts_header],
    docroot              => $vhost_docroot,
    proxy_pass_match     => [
      { path => '^/(.*\.php(/.*)?)$',
        url  => "fcgi://${vhost_fpm_root}${vhost_docroot}/\$1",
      },
      { path         => '^/wiki/',
        url          => "fcgi://${vhost_fpm_root}${vhost_docroot}/index.php",
        reverse_urls => [],
      },
    ],
    directories          => [
      $root_directory,
      { path     => "${vhost_docroot}/config",
        provider => 'directory',
        override => ['None'],
      },
      { path     => "${vhost_docroot}/images",
        provider => 'directory',
        override => ['None'],
      },
      { path     => "${vhost_docroot}/upload",
        provider => 'directory',
        override => ['None'],
      },
    ],
    require              => [
      File[$vhost_ssl_cert],
      File[$vhost_ssl_chain],
      File[$vhost_ssl_key],
      File[$config],
    ],
  }

  File[$vhost_ssl_cert, $vhost_ssl_chain, $vhost_ssl_key] ~> Class['Apache::Service']

  # Uses variables:
    # $vhost_name
    # $db_basename
    # $db_user
    # $db_host
    # $db_password
    # $secret_key
    # $upgrade_key
    # $site_name
  file {$config:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template('mediawiki/LocalSettings_vhost.php.erb'),
  }

  # Uses variables:
    # $vhost_name
    # $vhost_aliases
  concat::fragment {"mediawiki_config_meta_${vhost_name}":
    target  => $::mediawiki::config_meta,
    order   => '10',
    content => template('mediawiki/LocalSettings.php.erb')
  }
}
