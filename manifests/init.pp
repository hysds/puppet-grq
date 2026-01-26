#####################################################
# grq class
#####################################################

class grq inherits hysds_base {

  #####################################################
  # copy user files
  #####################################################
  
  file { "/$user/.bash_profile":
    ensure  => present,
    content => template('grq/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => "0644",
    require => User[$user],
  }


  #####################################################
  # get sciflo directory
  #####################################################

  $sciflo_dir = "/$user/sciflo"


  #####################################################
  # set admin mysql password
  #####################################################

  $mysql_user = "root"
  $mysql_password = "sciflo"

  #exec { "set-mysql-password":
  #  unless  => "mysqladmin -u$mysql_user -p$mysql_password status",
  #  path    => ["/bin", "/usr/bin"],
  #  command => "mysqladmin -u$mysql_user password $mysql_password",
  #  require => Exec["mariadb-start"],
  #}


  #####################################################
  # create grq/urlCatalog db and add user with all rights
  #####################################################

  #grq::mysqldb { 'grq':
  #  user           => $user,
  #  password       => '',
  #  admin_user     => $mysql_user, 
  #  admin_password => $mysql_password, 
  #  require        => Exec['set-mysql-password'],
  #}


  #grq::mysqldb { 'urlCatalog':
  #  user           => $user,
  #  password       => '',
  #  admin_user     => $mysql_user, 
  #  admin_password => $mysql_password, 
  #  require        => Exec['set-mysql-password'],
  #}


  file { '/etc/logrotate.d/mysql-backup':
    ensure  => file,
    content  => template('grq/mysql-backup'),
    mode    => "0644",
  }


  #####################################################
  # install packages
  #####################################################

  # Determine architecture for mod_evasive RPM
  $arch = $::architecture
  
  # Map architecture to mod_evasive RPM URL
  if $arch == 'x86_64' {
    $mod_evasive_rpm = 'https://dl.fedoraproject.org/pub/archive/epel/7/x86_64/Packages/m/mod_evasive-1.10.1-22.el7.x86_64.rpm'
  } elsif $arch == 'aarch64' {
    $mod_evasive_rpm = 'https://dl.fedoraproject.org/pub/archive/epel/7/aarch64/Packages/m/mod_evasive-1.10.1-22.el7.aarch64.rpm'
  } else {
    fail("Unsupported architecture: ${arch}")
  }

  package {
    'mailx': ensure => present;
    'httpd': ensure => present;
    'mod_ssl': ensure => present;
    #'mod_evasive': ensure => present;
    "${mod_evasive_rpm}": ensure => present;
    'geos-devel': ensure => installed;
    'proj-devel': ensure => installed;
    #'geos-python': ensure => installed;
    #'numpy': ensure => installed;
  }


  #####################################################
  # systemd daemon reload
  #####################################################

  exec { "daemon-reload":
    path        => ["/sbin", "/bin", "/usr/bin"],
    command     => "systemctl daemon-reload",
    refreshonly => true,
  }

  
  #####################################################
  # install OpenJDK 8 (multi-architecture compatible)
  # Uses system repositories instead of Oracle JDK RPMs
  #####################################################

  # Install OpenJDK 8 from system repositories
  # This works on both x86_64 and aarch64 without separate RPM files
  package { 'java-1.8.0-openjdk-devel':
    ensure => present,
    notify => Exec['ldconfig'],
  }

  # Set java alternatives to use OpenJDK 8
  # The path is architecture-independent for OpenJDK
  exec { 'set-java-alternatives':
    command => '/usr/sbin/alternatives --set java /usr/lib/jvm/jre-1.8.0-openjdk/bin/java',
    unless  => '/usr/sbin/alternatives --display java | grep "link currently points to /usr/lib/jvm/jre-1.8.0-openjdk/bin/java"',
    require => Package['java-1.8.0-openjdk-devel'],
  }


  #####################################################
  # install install_hysds.sh script in ops home
  #####################################################

  file { "/$user/install_hysds.sh":
    ensure  => present,
    content  => template('grq/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => "0755",
    require => User[$user],
  }


  #####################################################
  # install GRQ startup/shutdown scripts
  #####################################################

  file { ["$sciflo_dir",
          "$sciflo_dir/bin",
          "$sciflo_dir/etc"]:
    ensure  => directory,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    require => User[$user],
  }


  file { "$sciflo_dir/bin/start_grq":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('grq/start_grq'),
    require => File["$sciflo_dir/bin"],
  }


  file { "$sciflo_dir/bin/stop_grq":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => "0755",
    content => template('grq/stop_grq'),
    require => File["$sciflo_dir/bin"],
  }


  #####################################################
  # write rc.local to startup & shutdown grq
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('grq/rc.local'),
    mode    => "0755",
  }


  #####################################################
  # increase file descriptor limits for user apps: grq2
  #####################################################

  file { "/etc/security/limits.d/99-$user.conf":
    ensure  => file,
    content  => template('grq/limits.conf'),
    mode    => "0644",
  }


  #####################################################
  # generate ssl certs: problem with mod_ssl per
  # https://community.letsencrypt.org/t/localhost-crt-does-not-exist-or-is-empty/103979/4
  #####################################################

  exec { "httpd-ssl-gencerts":
    command => "/usr/libexec/httpd-ssl-gencerts",
    require => Package["mod_ssl"],
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('grq/autoindex.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('grq/welcome.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('grq/ssl.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('grq/index.html'),
    mode    => "0644",
    require => Package['httpd'],
  }


  file { "/var/log/mod_evasive":
    ensure  => directory,
    owner   => 'apache',
    group   => 'apache',
    mode    => "0755",
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/mod_evasive.conf":
    ensure  => present,
    content => template('grq/mod_evasive.conf'),
    mode    => "0644",
    require => Package['httpd'],
  }


  #service { 'httpd':
  #  ensure     => running,
  #  enable     => true,
  #  hasrestart => true,
  #  hasstatus  => true,
  #  require    => [
  #                 File['/etc/httpd/conf.d/autoindex.conf'],
  #                 File['/etc/httpd/conf.d/welcome.conf'],
  #                 File['/etc/httpd/conf.d/ssl.conf'],
  #                 File['/var/www/html/index.html'],
  #                 File['/var/log/mod_evasive'],
  #                 File['/etc/httpd/conf.d/mod_evasive.conf'],
  #                 Exec['daemon-reload'],
  #                ],
  #}


}
