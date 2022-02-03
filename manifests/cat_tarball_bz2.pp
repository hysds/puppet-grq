define grq::cat_tarball_bz2($pkg_tbz2=$title, $install_dir, $owner, $group, $creates) {

  # create the install directory
  file { "$install_dir":
    ensure  => directory,
    #owner   => $user,
    #group   => $group,
    mode    => "0755",
  }

  # cat the tarball parts
  exec { "cat $pkg_tbz2.*":
    creates => "/tmp/$pkg_tbz2",
    path    => ["/bin", "/usr/bin"],
    command => "cat /etc/puppetlabs/code/modules/grq/files/$pkg_tbz2.* > /tmp/$pkg_tbz2",
    notify  => Exec["untar $pkg_tbz2"],
  }

  # untar the tarball at the desired location
  exec { "untar $pkg_tbz2":
    creates     => $creates,
    path        => ["/bin", "/usr/bin", "/usr/sbin", "/sbin"],
    command     => "/bin/tar xjvf /tmp/$pkg_tbz2 --owner $owner --group $group -C $install_dir/",
    refreshonly => true,
    require     => [ Exec["cat $pkg_tbz2.*"], File["$install_dir"] ]
  }
}
