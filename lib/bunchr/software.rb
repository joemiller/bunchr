require 'rake'
require 'rake/tasklib'
require 'rake/clean'
require 'yaml'
require 'bunchr/utils'

module Bunchr

  class Software < ::Rake::TaskLib
    include ::Bunchr::Utils

    attr_accessor :name, :version
    attr_accessor :download_commands, :build_commands, :install_commands
    attr_accessor :download_environment, :build_environment, :install_environment

    def initialize()
      @name = nil
      @version = nil
      @install_commands = []
      @build_commands = []
      @download_commands = []
      @install_environment = {}
      @build_environment = {}
      @download_environment = {}
      yield self if block_given?
      define unless name.nil?
    end

    def download_dir
      File.join(Bunchr.build_dir, name)
    end

    # The directory this task unpacks into
    def work_dir
      @work_dir ||= File.join(download_dir, "#{name + (version ? "-#{version}" : "") }")
    end

    # override the directory that the local source unpacks into if it is not
    # +name-version+. If pd is an absolute path, use it. Otherwise, prepend with
    # @download_dir.
    def work_dir=(pd)
      if pd =~ /^\//
        @work_dir = pd
      else
        @work_dir = File.join(download_dir, pd)
      end
    end

    # Define all the tasks in the namespace of the +name+ of this task.
    #
    # The dependency chain is:
    #
    #   :install => :build => :download
    def define
      logger.debug "Defining tasks for software:#{name} #{version}"

      namespace 'software' do
        namespace name do
          define_download
          define_build
          define_install

          task :done    => "software:#{name}:install"
          task :default => "software:#{name}:done"
        end

        desc "Download, build, and install #{name} #{version}"
        task name => "#{name}:default"
      end

    end

    def define_download
      directory download_dir

      desc "Download #{name} #{version}"
      task :download => dotfile('download') do
        logger.info "#{name} #{version} downloaded"
      end

      file dotfile('download') => download_dir do
        logger.info "Downloading #{name} #{version}"
        Dir.chdir(download_dir) do
          download
        end
        dotfile!('download')
      end
      ::CLEAN << dotfile('download')
      ::CLEAN << download_dir
    end

    def define_build
      desc "Build #{name} #{version}"
      task :build => dotfile('build') do
        logger.info "#{name} #{version} built"
      end

      file dotfile('build') => "software:#{name}:download" do
        logger.info "Building #{name} #{version}"
        Dir.chdir(work_dir) do
          build
        end
        dotfile!('build')
      end
      ::CLEAN << dotfile('build')
    end

    def define_install
      desc "Install #{name} #{version}"
      task :install => dotfile('install')  do
        logger.info "#{name} #{version} is installed"
      end

      file dotfile('install') => "software:#{name}:build" do
        logger.info "Installing #{name} #{version}"
        Dir.chdir(work_dir) do
          install
        end
        dotfile!('install')
      end
      ::CLEAN << dotfile('install')

    end

    # Execute all the build commands
    def download
      download_commands.each do |cmd|
        sh(cmd, download_environment, download_dir)
      end
    end

    # Execute all the build commands
    def build
      build_commands.each do |cmd|
        sh(cmd, build_environment, work_dir)
      end
    end

    # Execute all the install commands
    def install
      install_commands.each do |cmd|
        sh(cmd, install_environment, work_dir)
      end
    end

    # depend on a {Bunchr::Software} object to be built and installed
    def depends_on(dependency)
      namespace 'software' do
        namespace name do
          task :build => "software:#{dependency}:done"
        end
      end
    end

    def dotfile(name)
      File.join(download_dir, ".#{name}")
    end

    def dotfile!(name)
      File.open(dotfile(name), "w") { |f| puts Time.now }
    end

  end
end
