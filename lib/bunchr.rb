module Bunchr
  require 'bunchr/software'
  require 'bunchr/packages'
  require 'bunchr/logger'
  require 'bunchr/utils'
  require 'bunchr/ohai'

  # global module variables that must be set ay a Bunchr project and will
  # be used by Bunchr::Software and ::Packages tasks.
  @@build_dir = nil
  @@install_dir = nil

  class << self
    include Rake::DSL if RAKEVERSION >= '0.9.0' 
  
    def install_dir
      if @@install_dir.nil?
        raise "You must set `Bunchr.install_dir = '/path'` in your Rakefile."
      end
      @@install_dir
    end

    def install_dir=(dir)
      @@install_dir = dir
    end

    def build_dir
      if @@build_dir.nil?
        raise "You must set `Bunchr.build_dir = '/path'` in your Rakefile."
      end
      @@build_dir
    end

    def build_dir=(dir)
      @@build_dir = dir
    end

    # simple wrapper around Rake's import() method for loading .rake files
    def load_recipes(*files)
      files.flatten.each { |f| import f }
    end
  end

end
