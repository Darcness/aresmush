# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    PLUGIN_NAME = 'wod5e'

    def self.plugin_dir
      File.dirname(__FILE__)
    end

    def self.shortcuts
      Global.read_config(PLUGIN_NAME, 'shortcuts')
    end

    def self.get_cmd_handler(_client, cmd, _enactor)
      case cmd.root
      when 'sheet'
        case cmd.switch
        when 'set'
          SheetSetCmd
        when 'show'
          SheetShowCmd
        else
          SheetCmd
        end
      end
    end

    @@character_types = { # rubocop:disable Style/ClassVars
      Hunter: 'hunter'
    }

    def self.character_types
      @@character_types
    end
  end
end
