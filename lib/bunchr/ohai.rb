require 'ohai'

module Bunchr
  class Ohai

    @@ohai = nil

    def self.ohai
      if @@ohai.nil?
        @@ohai ||= ::Ohai::System.new
        @@ohai.load_plugins
        @@ohai.require_plugin('os')
        @@ohai.require_plugin('platform')
      end
      @@ohai
    end

  end
end
