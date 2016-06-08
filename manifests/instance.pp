define mediawiki::instance (
  $vhost_name,
  $vhost_aliases,
  $vhost_ssl_protocol,
  $vhost_ssl_honorcipherorder,
  $vhost_ssl_cipher,
  $vhost_ssl_cert,
  $vhost_ssl_ca,
  $vhost_ssl_key,
  $vhost_ssl_hsts_header,
  $vhost_docroot,
  $vhost_fpm_root,
  $vhost_basic_auth,
  $db_user,
  $db_basename,
  $db_host,
  $db_password,
  $secret_key,
  $upgrade_key
  ){
    $vhost_basic_auth_file = "/etc/apache2/mediawiki_${vhost_name}http_auth"
    $config = "/etc/mediawiki/LocalSettings_${vhost_name}.php"


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
    port            => '80',
    docroot         => $vhost_docroot,
    redirect_status => 'permanent',
    redirect_dest   => "https://${vhost_name}/",
  }

  if $vhost_basic_auth {
    file {$vhost_basic_auth_file:
      ensure  => present,
      owner   => 'root',
      group   => 'www-data',
      mode    => '0640',
      content => $vhost_basic_auth,
    }
    $root_directory = [{
      path           => '/',
      provider       => 'location',
      auth_type      => 'Basic',
      auth_name      => 'Software Heritage development',
      auth_user_file => $vhost_basic_auth_file,
      auth_require   => 'valid-user',
    }]
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
    port                 => '443',
    ssl                  => true,
    ssl_protocol         => $vhost_ssl_protocol,
    ssl_honorcipherorder => $vhost_ssl_honorcipherorder,
    ssl_cipher           => $vhost_ssl_cipher,
    ssl_cert             => $vhost_ssl_cert,
    ssl_ca               => $vhost_ssl_ca,
    ssl_key              => $vhost_ssl_key,
    headers              => [$vhost_ssl_hsts_header],
    docroot              => $vhost_docroot,
    proxy_pass_match     => [
      { path => '^/(.*\.php(/.*)?)$',
        url  => "fcgi://${vhost_fpm_root}${vhost_docroot}/\$1",
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
      File[$vhost_ssl_ca],
      File[$vhost_ssl_key],
      File[$config],
    ],
  }

  # Uses variables:
    # $vhost_name
    # $db_basename
    # $db_user
    # $db_host
    # $db_password
    # $secret_key
    # $upgrade_key
  file {$config:
    ensure  => present,
    owner   => 'root',
    group   => 'www-data',
    mode    => '0640',
    content => template('mediawiki/LocalSettings_vhost.php.erb'),
    notify  => Service['php5-fpm'],
  }
}
