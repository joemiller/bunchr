require 'logger'

module Bunchr
  class Logger

    @@log = nil

    def self.logger()
      if @@log.nil?
        @@log ||= ::Logger.new(STDOUT)
        @@log.level = ENV['BUNCHR_DEBUG'] ? ::Logger::DEBUG : ::Logger::INFO
        # @@log.level = ::Logger::DEBUG
      end
      @@log
    end

  end
end
