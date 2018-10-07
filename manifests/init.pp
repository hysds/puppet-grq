#####################################################
# grq class
#####################################################

class grq inherits hysds_base {

  #####################################################
  # copy user files
  #####################################################
  
  file { "/home/$user/.bash_profile":
    ensure  => present,
    content => template('grq/bash_profile'),
    owner   => $user,
    group   => $group,
    mode    => 0644,
    require => User[$user],
  }


  #####################################################
  # get sciflo directory
  #####################################################

  $sciflo_dir = "/home/$user/sciflo"


  #####################################################
  # set admin mysql password
  #####################################################

  $mysql_user = "root"
  $mysql_password = "sciflo"

  exec { "set-mysql-password":
    unless  => "mysqladmin -u$mysql_user -p$mysql_password status",
    path    => ["/bin", "/usr/bin"],
    command => "mysqladmin -u$mysql_user password $mysql_password",
    require => Exec["mariadb-start"],
  }


  #####################################################
  # create grq/urlCatalog db and add user with all rights
  #####################################################

  mysqldb { 'grq':
    user           => $user,
    password       => '',
    admin_user     => $mysql_user, 
    admin_password => $mysql_password, 
    require        => Exec['set-mysql-password'],
  }


  mysqldb { 'urlCatalog':
    user           => $user,
    password       => '',
    admin_user     => $mysql_user, 
    admin_password => $mysql_password, 
    require        => Exec['set-mysql-password'],
  }


  file { '/etc/logrotate.d/mysql-backup':
    ensure  => file,
    content  => template('grq/mysql-backup'),
    mode    => 0644,
  }


  #####################################################
  # install packages
  #####################################################

  package {
    'mailx': ensure => present;
    'httpd': ensure => present;
    'mod_ssl': ensure => present;
    'mod_evasive': ensure => present;
    'geos-devel': ensure => installed;
    'proj-devel': ensure => installed;
    'geos-python': ensure => installed;
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
  # install oracle java and set default
  #####################################################

  $jdk_rpm_file = "jdk-8u60-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppet/modules/grq/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.0_60"
  $java_bin_path = "/usr/java/$jdk_pkg_name/jre/bin/java"


  cat_split_file { "$jdk_rpm_file":
    install_dir => "/etc/puppet/modules/grq/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { "$jdk_pkg_name":
    provider => rpm,
    ensure   => present,
    source   => $jdk_rpm_path,
    notify   => Exec['ldconfig'],
    require     => Cat_split_file["$jdk_rpm_file"],
  }


  update_alternatives { 'java':
    path     => $java_bin_path,
    require  => [
                 Package[$jdk_pkg_name],
                 Exec['ldconfig']
                ],
  }


  #####################################################
  # install install_hysds.sh script in ops home
  #####################################################

  file { "/home/$user/install_hysds.sh":
    ensure  => present,
    content  => template('grq/install_hysds.sh'),
    owner   => $user,
    group   => $group,
    mode    => 0755,
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
    mode    => 0755,
    require => User[$user],
  }


  file { "$sciflo_dir/bin/start_grq":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('grq/start_grq'),
    require => File["$sciflo_dir/bin"],
  }


  file { "$sciflo_dir/bin/stop_grq":
    ensure  => present,
    owner   => $user,
    group   => $group,
    mode    => 0755,
    content => template('grq/stop_grq'),
    require => File["$sciflo_dir/bin"],
  }


  #####################################################
  # write rc.local to startup & shutdown grq
  #####################################################

  file { '/etc/rc.d/rc.local':
    ensure  => file,
    content  => template('grq/rc.local'),
    mode    => 0755,
  }


  #####################################################
  # increase file descriptor limits for user apps: grq2
  #####################################################

  file { "/etc/security/limits.d/99-$user.conf":
    ensure  => file,
    content  => template('grq/limits.conf'),
    mode    => 0644,
  }


  #####################################################
  # secure and start httpd
  #####################################################

  file { "/etc/httpd/conf.d/autoindex.conf":
    ensure  => present,
    content => template('grq/autoindex.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/welcome.conf":
    ensure  => present,
    content => template('grq/welcome.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/ssl.conf":
    ensure  => present,
    content => template('grq/ssl.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { '/var/www/html/index.html':
    ensure  => file,
    content => template('grq/index.html'),
    mode    => 0644,
    require => Package['httpd'],
  }


  file { "/var/log/mod_evasive":
    ensure  => directory,
    owner   => 'apache',
    group   => 'apache',
    mode    => 0755,
    require => Package['httpd'],
  }


  file { "/etc/httpd/conf.d/mod_evasive.conf":
    ensure  => present,
    content => template('grq/mod_evasive.conf'),
    mode    => 0644,
    require => Package['httpd'],
  }


  service { 'httpd':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/httpd/conf.d/autoindex.conf'],
                   File['/etc/httpd/conf.d/welcome.conf'],
                   File['/etc/httpd/conf.d/ssl.conf'],
                   File['/var/www/html/index.html'],
                   File['/var/log/mod_evasive'],
                   File['/etc/httpd/conf.d/mod_evasive.conf'],
                   Exec['daemon-reload'],
                  ],
  }


}
