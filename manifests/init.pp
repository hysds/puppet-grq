#####################################################
# grq class
#####################################################

class grq inherits scientific_python {

  #####################################################
  # add swap file 
  #####################################################

  swap { '/mnt/swapfile':
    ensure   => present,
  }


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
    require => Service["mariadb"],
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
    'httpd-devel': ensure => present;
    'mod_ssl': ensure => present;
    'mod_evasive': ensure => present;
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

  $jdk_rpm_file = "jdk-8u241-linux-x64.rpm"
  $jdk_rpm_path = "/etc/puppet/modules/grq/files/$jdk_rpm_file"
  $jdk_pkg_name = "jdk1.8.x86_64"
  $java_bin_path = "/usr/java/jdk1.8.0_241-amd64/jre/bin/java"


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
  # get integer memory size in MB
  #####################################################

  if '.' in $::memorysize_mb {
    $ms = split("$::memorysize_mb", '[.]')
    $msize_mb = $ms[0]
  }
  else {
    $msize_mb = $::memorysize_mb
  }


  #####################################################
  # install elasticsearch
  #####################################################

  $es_heap_size = $msize_mb / 2
  $es_rpm_file = "elasticsearch-7.1.1-x86_64.rpm"
  $es_rpm_path = "/etc/puppet/modules/grq/files/$es_rpm_file"


  cat_split_file { "$es_rpm_file":
    install_dir => "/etc/puppet/modules/grq/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { 'elasticsearch':
    provider => rpm,
    ensure   => present,
    source   => $es_rpm_path,
    require  => [
                  Cat_split_file["$es_rpm_file"],
                  Exec['set-java'],
                ],
  }


  file { "/etc/security/limits.d/99-elasticsearch.conf":
    ensure       => file,
    content      => template('grq/99-elasticsearch.conf'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/sysconfig/elasticsearch':
    ensure       => file,
    content      => template('grq/elasticsearch'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/elasticsearch.yml':
    ensure       => file,
    content      => template('grq/elasticsearch.yml'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { '/etc/elasticsearch/log4j2.properties':
    ensure       => file,
    content      => template('grq/log4j2.properties'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  file { "/usr/lib/systemd/system/elasticsearch.service":
    ensure       => file,
    content      => template('grq/elasticsearch.service'),
    mode         => 0644,
    require      => Package['elasticsearch'],
  }


  cat_tarball_bz2 { "elasticsearch-data.tbz2":
    install_dir => "/var/lib",
    creates     => "/var/lib/elasticsearch/products_cluster/nodes/0/indices/geonames",
    owner       => "elasticsearch",
    group       => "elasticsearch",
    require     => Package['elasticsearch'],
  }


  service { 'elasticsearch':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    provider   => init,
    require    => [
                   File['/etc/security/limits.d/99-elasticsearch.conf'],
                   File['/etc/sysconfig/elasticsearch'],
                   File['/etc/elasticsearch/elasticsearch.yml'],
                   File['/etc/elasticsearch/log4j2.properties'],
                   File['/usr/lib/systemd/system/elasticsearch.service'],
                   Cat_tarball_bz2['elasticsearch-data.tbz2'],
                   Exec['daemon-reload'],
                  ],
  }


  $cerebro_rpm_file = "cerebro-0.8.5-1.noarch.rpm"
  $cerebro_rpm_path = "/etc/puppet/modules/grq/files/$cerebro_rpm_file"


  cat_split_file { "$cerebro_rpm_file":
    install_dir => "/etc/puppet/modules/grq/files",
    owner       =>  $user,
    group       =>  $group,
  }


  package { 'cerebro':
    provider => rpm,
    ensure   => present,
    source   => $cerebro_rpm_path,
    require  => [
                  Cat_split_file["$cerebro_rpm_file"],
                  Service['elasticsearch'],
                  Exec['set-java'],
                ],
  }


  file { '/usr/lib/systemd/system/cerebro.service':
    ensure       => file,
    content      => template('grq/cerebro.service'),
    mode         => 0644,
    require      => Package['cerebro'],
  }


  service { 'cerebro':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   Package['cerebro'],
                   Exec['daemon-reload'],
                  ],
    subscribe  => File['/usr/lib/systemd/system/cerebro.service'],
  }


  #####################################################
  # disable transparent hugepages for redis
  #####################################################

  file { "/etc/tuned/no-thp":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/tuned/no-thp/tuned.conf":
    ensure  => file,
    content => template('grq/tuned.conf'),
    mode    => 0644,
    require => File["/etc/tuned/no-thp"],
  }

  
  exec { "no-thp":
    unless  => "grep -q -e '^no-thp$' /etc/tuned/active_profile",
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "tuned-adm profile no-thp",
    require => File["/etc/tuned/no-thp/tuned.conf"],
  }


  #####################################################
  # tune kernel for high performance
  #####################################################

  file { "/usr/lib/sysctl.d":
    ensure  => directory,
    mode    => 0755,
  }


  file { "/usr/lib/sysctl.d/grq.conf":
    ensure  => present,
    content => template('grq/grq.conf'),
    mode    => 0644,
    require => File["/usr/lib/sysctl.d"],
  }


  exec { "sysctl-system":
    path    => ["/sbin", "/bin", "/usr/bin"],
    command => "/sbin/sysctl --system",
    require => File["/usr/lib/sysctl.d/grq.conf"],
  }


  #####################################################
  # install redis
  #####################################################

  package { "redis":
    ensure   => present,
    notify   => Exec['ldconfig'],
    require => [
                Exec["no-thp"],
                Exec["sysctl-system"],
               ],
  }


  file { '/etc/redis.conf':
    ensure       => file,
    content      => template('grq/redis.conf'),
    mode         => 0644,
    require      => Package['redis'],
  } 


  file { ["/etc/systemd/system/redis.service.d",
         "/etc/systemd/system/redis-sentinel.service.d"]:
    ensure  => directory,
    mode    => 0755,
  }


  file { "/etc/systemd/system/redis.service.d/limit.conf":
    ensure  => present,
    content => template('grq/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis.service.d"],
  }


  file { "/etc/systemd/system/redis-sentinel.service.d/limit.conf":
    ensure  => present,
    content => template('grq/redis_service.conf'),
    mode    => 0644,
    require => File["/etc/systemd/system/redis-sentinel.service.d"],
  }


  service { 'redis':
    ensure     => running,
    enable     => true,
    hasrestart => true,
    hasstatus  => true,
    require    => [
                   File['/etc/redis.conf'],
                   File['/etc/systemd/system/redis.service.d/limit.conf'],
                   File['/etc/systemd/system/redis-sentinel.service.d/limit.conf'],
                   Exec['daemon-reload'],
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


  #####################################################
  # firewalld config
  #####################################################

  firewalld::zone { 'public':
    services => [ "ssh", "dhcpv6-client", "http", "https" ],
    ports => [
      { 
        # Cerebro (ES web admin tool)
        port     => "9000",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9200",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "tcp",
      },
      {
        # ElasticSearch
        port     => "9300",
        protocol => "udp",
      },
      {
        # Redis
        port     => "6379",
        protocol => "tcp",
      },
      {
        # Pele REST Service
        port     => "8877",
        protocol => "tcp",
      },
      {
        # GRQ (GeoRegionQuery) REST Service
        port     => "8878",
        protocol => "tcp",
      },
      {
        # Tosca (Product FacetView) Web App
        port     => "8879",
        protocol => "tcp",
      },
    ]
  }


  #firewalld::service { 'dummy':
  #  description	=> 'My dummy service',
  #  ports       => [{port => '1234', protocol => 'tcp',},],
  #  modules     => ['some_module_to_load'],
  #  destination	=> {ipv4 => '224.0.0.251', ipv6 => 'ff02::fb'},
  #}


}
