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
        when 'init'
          SheetInitCmd
        else
          SheetCmd
        end
      end
    end

    def self.build_web_profile_data(char, enactor)
      { sheet: char.sheet.to_h }
    end

    # @yieldparam model [Character]
    def self.validate_sheet(target_name, client, enactor, &block) # rubocop:disable Lint/UnusedMethodArgument
      ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
        if model.wod5e_sheet.nil?
          client.emit_failure(t('wod5e.sheet_obj_missing', name: model.name))
          next
        end

        yield model
      end
    end
  end
end
