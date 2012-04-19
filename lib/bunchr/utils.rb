require 'systemu'
require 'bunchr/logger'
require 'bunchr/ohai'

module Bunchr
  module Utils

    # Execute a shell command, with optional environment. stdout and stderr
    # will be sent to the logger if the command exits with non-zero status.
    def sh(cmd, env={}, dir=nil)
      logger.info("Executing: [#{cmd.gsub(/\s{2,}/, ' ')}]")

      output = ''
      status = systemu("#{cmd}", 
                       :stdout => output,
                       :stderr => output,
                       :env => env,
                       :cwd => dir)
      if status.exitstatus > 0
        logger << output
        fail "Command failed with status (#{status.exitstatus}): [#{cmd.gsub(/\s{2,}/, ' ')}]."
      end
    end

    # handle to the top level logger
    def logger
      Bunchr::Logger.logger
    end

    # handle to the top level ohai for generic system information
    def ohai
      Bunchr::Ohai.ohai
    end

  end
end