# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config('wod5e', 'shortcuts')
    end

    def self.get_cmd_handler(_client, cmd, _enactor)
      case cmd.root
      when 'attribute'
        AresMUSH::WoD5e::AttributesCmd
      end
    end
  end
end
