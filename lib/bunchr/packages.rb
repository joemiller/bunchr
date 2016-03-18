require 'rake'
require 'rake/tasklib'
require 'rake/clean'
require 'bunchr/utils'

module Bunchr

  class Packages < ::Rake::TaskLib
    include ::Bunchr::Utils

    # only attempt to build .rpm's on these platforms (as reported by
    # ohai.platform)
    RPM_PLATFORMS = %w[centos redhat fedora scientific suse]

    # only attempt to build .deb's on these platforms (as reported by
    # ohai.platform)
    DEB_PLATFORMS = %w[debian ubuntu raspbian]

    attr_accessor :name, :version, :iteration, :license, :vendor, :maintainer, :url, :category
    attr_accessor :description
    attr_accessor :files, :config_files, :scripts

  	def initialize
      @name = nil
      @version = nil
      @iteration = nil
      @arch = ohai['kernel']['machine']
      @license = nil
      @vendor = nil
      @maintainer = nil
      @category = nil
      @url = nil
      @description = nil
      @files = []
      @config_files = []
      @scripts = {}
      yield self if block_given?
      define unless name.nil? or version.nil?
    end

    #
    # returns the current architecture. Convert some architectures for the
    # underlying packaging systems, such as i686 to i386.
    def arch
      case @arch
      when 'i686', 'i386'
        'i386'
      else
        @arch
      end
    end

    # explicitly set @arch to `a`
    def arch=(a)
      @arch = a
    end

    def define
      logger.debug "Defining tasks for package:#{name} #{version}"

      namespace 'packages' do
        namespace name do
          define_build_tarball
          define_build_rpm
          define_build_deb
          # TODO-future: build solaris pkgs, windows too?!

          define_build_all

          task :done    => "#{name}:build"
          task :default => "#{name}:done"
        end
        desc "Create bunchr packages for #{name} #{version}-#{iteration}"
        task name => "#{name}:default"
      end
    end

    def define_build_tarball
      tarball_name = "#{name}-#{version}-#{iteration}-#{arch}.tar.gz"

      desc "Build tarball: #{tarball_name}"
      task :build_tarball do

        logger.info "Building tarball '#{tarball_name}'"

        files_str = files.join(' ') + ' ' + config_files.join(' ')
        sh "tar czf #{tarball_name} #{files_str}"
      end
    end

    def define_build_rpm
      desc "Build RPM: #{name}-#{version}-#{iteration}-#{arch}"
      task :build_rpm do

        if RPM_PLATFORMS.include? ohai.platform
          logger.info "Building RPM '#{name}-#{version}-#{iteration}-#{arch}'"

          sh "fpm -s dir -t rpm -a #{arch} -n #{name} -v #{version} \
              --iteration #{iteration}                              \
              --url         '#{url}'                                \
              --description '#{description}'                        \
              --license     '#{license}'                            \
              --vendor      '#{vendor}'                             \
              --category    '#{category}'                           \
              --maintainer  '#{maintainer}'                         \
              #{fpm_scripts_args}                                   \
              #{fpm_config_files_args}                              \
              #{config_files.join(' ')}                             \
              #{files.join(' ')}"

          logger.info "RPM built."
        else
          logger.info "Not building RPM, platform [#{ohai.platform}] does not support it."
        end

      end
    end

    def define_build_deb
      desc "Build deb: #{name}-#{version}-#{iteration}-#{arch}"
      task :build_deb do

        if DEB_PLATFORMS.include? ohai.platform
           # Instead of guessing architecture from the kernel, ask the packager
          @arch = `dpkg --print-architecture`.strip()
          logger.info "Building DEB '#{name}-#{version}-#{iteration}-#{arch}'"

          sh "fpm -s dir -t deb -a #{arch} -n #{name} -v #{version} \
              --iteration #{iteration}                              \
              --url         '#{url}'                                \
              --description '#{description}'                        \
              --license     '#{license}'                            \
              --vendor      '#{vendor}'                             \
              --category    '#{category}'                           \
              --maintainer  '#{maintainer}'                         \
              #{fpm_scripts_args}                                   \
              #{fpm_config_files_args}                              \
              #{config_files.join(' ')}                             \
              #{files.join(' ')}"

          logger.info "DEB built."
        else
          logger.info "Not building DEB, platform [#{ohai.platform}] does not support it."
        end

      end
    end

    def define_build_all
      desc "Build all packages: #{name}-#{version}-#{iteration}-#{arch}"
      task :build => [:build_tarball, :build_rpm, :build_deb]
    end

    # depend on a {Bunchr::Software} object to be built and installed
    def include_software(other_dependency)
      namespace 'packages' do
        namespace name do
          task :build => "software:#{other_dependency}:done"
        end
      end
    end

    # return an argument string for fpm with '--config-files' prefixed to
    # every file in the config_files array.
    #   eg: '--config-files /etc/file1 --config-files /etc/file2'
    def fpm_config_files_args
      config_files.map { |f| '--config-files ' + f }.join(' ')
    end

    # returns an argument string for fpm with files from the scripts hash, eg:
    #  scripts[:after_install] = 'file1'
    #  scripts[:before_remove] = 'file2'
    #  fpm_scripts_args() # => '--after-install file1 --before-remove file2'
    def fpm_scripts_args
      scripts.map do |k,v|
        "--#{k.to_s.tr('_','-')} #{v}" << ' '
      end.join(' ')
    end

  end
end
