Bunchr
======

Overview
--------

Bunchr is a Rake/Ruby-based DSL for building and bundling complex software
projects into various package formats, ie: RPM, DEB, etc (packaging performed
by [fpm](https://github.com/jordansissel/fpm).

Originally developed to create "omnibus" style packages that include an entire
ruby stack along with one or more gems, but useful for general compilation and
packaging as well.

It is typically intended to be used in conjunction with [Vagrant](http://vagrantup.com)
but can be used without Vagrant as well.

History
-------

Bunchr was conceived as a tool to help the [Sensu](https://github.com/sensu) 
monitoring project find a better way to create packages that would be as
easy as possible to deploy on a variety of platforms with minimal friction and
with little or no knowledge about the idiosyncrasies of the Ruby universe
(version incompatibilities, gem conflicts, etc). This was particularly desirable
for Sensu because one of the components is an agent that will be installed
on most or all servers in an infrastructure. Thus, the package should be easy
to install and should not interfere with any other Ruby apps or scripts on the
server.

About the time the Sensu project was discussing a new packaging approach,
(Adam Jacob) from [Opscode/Chef](http://opscode.com/) took notice and suggested
a slightly different approach that achieved the same goals. The approach was
called 'omnibus' and was already in use at Opscode to produce a simple and
uniform installer for Chef.

Opscode was using a Clojure-based tool at the time called [omnibus](https://github.com/opscode/omnibus)
and were working on a Ruby-based version of omnibus as well.

However, the Ruby based Omnibus was not available at the time, so Bunchr was
created and it re-implements many of the concepts of the Clojure-based Omnibus
but on top of Ruby / Rake with a few differences.

Installation
------------

```
gem install bunchr
```

DSL Overview
------------

A typical Bunchr project is comprised of one or more `Bunchr::Software` objects
and a single `Bunchr::Packages` object. Define these all in a `Rakefile` or
separate them into files.

`Software` objects are responsible for downloading, building, and installing
a single software component, such as `zlib` or `ruby`. `Software` objects
support platform-specific compilation options by making Ohai data available
for decision making.

`Packages` objects are used to combine `Software` objects into a single package.
It will automatically try to generate any packages supported by the current
platform, for example, RPMs will be built if the platform supports it, DEB
will be built if the platform supports it.

The goal is to be able to use a single code base to build _and_ package a 
project on multiple platforms.

Currently supported package types:

* tar.gz
* .deb
* .rpm

### Software DSL

* Example software recipes: https://github.com/joemiller/bunchr/tree/master/example_recipes

Example recipe for building and installing `ruby`:

```
Bunchr::Software.new do |t|
  t.name = 'ruby'
  t.version = '1.9.3-p125'

  t.depends_on('autoconf')
  t.depends_on('zlib')
  t.depends_on('openssl')
  t.depends_on('libyaml')

  install_prefix = "#{Bunchr.install_dir}/embedded"

  os   = t.ohai['os']
  arch = t.ohai['kernel']['machine']

  t.download_commands << "curl -O http://ftp.ruby-lang.org/pub/ruby/1.9/ruby-1.9.3-p125.tar.gz"
  t.download_commands << "tar xfvz ruby-1.9.3-p125.tar.gz"

  if os == 'darwin' && arch == 'x86_64'
    t.build_environment['LDFLAGS'] = "-arch x86_64 -R#{install_prefix}/lib -L#{install_prefix}/lib -I#{install_prefix}/include"
    t.build_environment['CFLAGS'] = "-arch x86_64 -m64 -L#{install_prefix}/lib -I#{install_prefix}/include"
  elsif os == 'linux'
    t.build_environment['LDFLAGS'] = "-Wl,-rpath #{install_prefix}/lib -L#{install_prefix}/lib -I#{install_prefix}/include"
    t.build_environment['CFLAGS'] = "-L#{install_prefix}/lib -I#{install_prefix}/include"
  elsif os == 'solaris2'
    t.build_environment['LDFLAGS'] = "-R#{install_prefix}/lib -L#{install_prefix}/lib -I#{install_prefix}/include"
    t.build_environment['CFLAGS'] = "-L#{install_prefix}/lib -I#{install_prefix}/include"
  end

  t.build_commands << "./configure --prefix=#{install_prefix} \
                      --with-opt-dir=#{install_prefix} \
                      --enable-shared \
                      --disable-install-doc"
  t.build_commands << "make"

  t.install_commands << "make install"

  CLEAN << install_prefix
end
```

* `t.name` - Required. Name of the software component.

* `t.version` - Optional. Version of the software component.

* `t.depends_on(name)` - Optional. This is used to tell Bunchr that other
  `Software` components should be built before this one.

* `t.ohai` - This provides access to the `Bunchr::Ohai` object which contains
  Ohai data about the system. By default, only the `platform` and `os` plugins
  are loaded. Since you have direct access to the Ohai object, other plugins 
  can be loaded by calling `t.ohai.require_plugin`

* `t.download_commands` - An array of shell commands used to download and 
  uncompress the source. You could also do a `git clone ..` here. These commands
  are executed in the `download_dir` which is `#{Bunchr.build_dir}/#{t.name}`.
  The `download_dir` cannot be changed.

* `t.build_commands` - An array of shell commands used to compile the downloaded 
  source. These commands are executed in the directory defined by 
  `t.work_dir` which will be automatically determined from: 
  1) `#{download_dir}/#{t.name}-#{t.version}` (common for most tarballs), or 
  2) `#{download_dir}/#{t.name}` (if no `t.version` set), or
  3) explicitly set by calling `t.work_dir = '/some/absolute/path'`

* `t.install_commands` - An array of shell commands used to download and 
  uncompress the source. You could also do a `git clone ..` here. These commands
  are executed in `t.work_dir` directory.

* `CLEAN` - Optional. This is an array of files and directories that should be deleted
  when `rake clean` is executed.

`download_commands`, `build_commands`, and `install_commands` are all optional,
but unless one of them contains some commands your `Software` object won't be
doing anything useful.

If any of `download_commands`, `build_commands`, or `install_commands` exit
with a non-zero status, the entire Bunchr process will stop
and print any STDOUT or STDERR from the failed command to the Logger.

Bunchr will keep track of what has succeeded so that you can restart a failed
build after fixing an error. This can save quite a bit of time during package
development, but you should consider doing a full `rake clean` before building
any official packages.


All tasks created by a `Bunchr::Software` object are prefixed into the 
`software:` namespace. To see the generated tasks:

```
$ rake -T software:ruby
rake software:ruby           # Download, build, and install ruby 1.9.3-p125
rake software:ruby:build     # Build ruby 1.9.3-p125
rake software:ruby:download  # Download ruby 1.9.3-p125
rake software:ruby:install   # Install ruby 1.9.3-p125
```

`Software` recipes can be defined directly in the Rakefile or they can
be separated into individual files and loaded via `Bunchr.load_recipes(files)`.

### Packages DSL

A project will typically only contain a single `Bunchr::Packages` object which
is essentially a wrapper around `fpm` to create a single package. The Ohai 
`platform` data will be used to determined what type of packages can be built
on the current system. Typically you would run the same Bunchr code on a
Debian based box to build the .deb, and a Redhat based box to build the .rpm.

Example `Rakefile`:

```
require 'bunchr'

Bunchr.build_dir   = '/tmp/build'
Bunchr.install_dir = '/opt/sensu'

Bunchr.load_recipes Dir['recipes/**/*.rake']

Bunchr::Packages.new do |t|
  t.name = 'sensu'
  t.version = ENV['SENSU_VERSION'] || '0.9.5'
  t.iteration = ENV['BUILD_NUMBER'] || '1'

  t.category = 'Monitoring'
  t.license  = 'MIT License'
  t.vendor   = 'Sonian Inc.'
  t.url      = 'https://github.com/sonian/sensu'
  t.description = 'A monitoring framework that aims to be simple, malleable, and scalable. Publish/subscribe model.'

  case t.ohai.platform_family
  when 'debian'
    t.scripts[:after_install]  = 'pkg_scripts/deb/postinst'
    t.scripts[:before_remove]  = 'pkg_scripts/deb/prerm'
    t.scripts[:after_remove]   = 'pkg_scripts/deb/postrm'
  when 'rhel', 'fedora'
    t.scripts[:before_install] = 'pkg_scripts/rpm/pre'
    t.scripts[:after_install]  = 'pkg_scripts/rpm/post'
    t.scripts[:before_remove]  = 'pkg_scripts/rpm/preun'
  end

  t.include_software('ruby')
  t.include_software('sensu')
  t.include_software('sensu_dashboard')
  t.include_software('sensu_configs')
  t.include_software('sensu_bin_stubs')

  t.files << Bunchr.install_dir    # /opt/sensu
  t.files << '/usr/share/sensu'
  t.files << '/var/log/sensu'

  t.files << '/etc/init.d/sensu-api'
  t.files << '/etc/init.d/sensu-client'
  t.files << '/etc/init.d/sensu-server'
  t.files << '/etc/init.d/sensu-dashboard'

  # need to enumerate config files for fpm
  # these are installed from recipe/sensu_configs.rake
  t.config_files << "/etc/sensu/handlers/default"
  t.config_files << "/etc/sensu/conf.d/client.json"
  t.config_files << "/etc/sensu/conf.d/checks.json"
  t.config_files << "/etc/sensu/conf.d/handlers.json"
  t.config_files << "/etc/sensu/config.json"

  t.config_files << '/etc/logrotate.d/sensu'
end

# default task executed when `rake` is run with no args.
task :default => ['packages:sensu']
```

Let's break it all down:

* `Bunchr.build_dir` - Required. This variable is available to all
   `Bunchr::Software` recipes specifying a temporary directory used for
   downloading and compiling.
  
* `Bunchr.install_dir` - Required. This variable is available to all
   `Bunchr::Software` recipes. It will typically be the base directory
   where all software is installed.

The following variables are used to drive `fpm` when building packages:

* `t.name`, `t.version`, `t.iteration` - Required. 
   Used by `fpm` to construct the package names, ie:
   `name-version-iteration-arch.rpm`

* `t.arch` - Optional. Can be used to override the default detected
   architecture, eg: `all` or `noarch`.

* `t.category`, `t.license`, `t.vendor`, `t.url`, `t.description` -
  Optional. Package metadata.

* `t.include_software(name)` - Optional. This is used to tell Bunchr what 
   `Software` components should be built and installed before creating
   packages.

* `t.scripts` - Optional. A hash with keys: `:after_install`, `:before_install`,
   `:after_remove`, and `:before_remove`. The specified files will be included
   with the packages.

* `t.files` - Required. An array of files and directories to include.

* `t.config_files` - Optional. An array of files that will be marked as 
   configuration files (if supported by the underlying package type).
   Config_files are automatically added to the `t.files` array.

   NOTE: you must specify individual files, not directories.

All tasks created by a `Bunchr::Packages` object are prefixed into the 
`packages:` namespace. To see the generated tasks:

```
$ rake -T packages
rake packages:sensu                # Create bunchr packages for sensu 0.9.5-1
rake packages:sensu:build          # Build all packages: sensu-0.9.5-1-x86_64
rake packages:sensu:build_deb      # Build deb: sensu-0.9.5-1-x86_64
rake packages:sensu:build_rpm      # Build RPM: sensu-0.9.5-1-x86_64
rake packages:sensu:build_tarball  # Build tarball: sensu-0.9.5-1-x86_64.tar.gz
```

The main task is `packages:#{name}`. Exec this task to create all relevant
packages.

Integration with Vagrant
------------------------

* TODO. maybe link to sensu-bunchr here.

Other Examples
--------------

* TODO. maybe link to sensu-bunchr here, or a complete example of fpm

Author
------

* [Joe Miller](https://twitter.com/miller_joe) - http://joemiller.me / https://github.com/joemiller

Licensing
---------
todo, apache
