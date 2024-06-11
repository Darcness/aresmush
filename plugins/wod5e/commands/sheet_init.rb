# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet command
    class SheetInitCmd
      include AresMUSH::CommandHandler

      attr_accessor :target_name, :character_type, :confirm

      def parse_args
        args = cmd.parse_args(ArgParser.flexible_args)
        @target_name = titlecase_arg(args.arg1)
        @character_type = args.arg2
        @confirm = args.arg3&.downcase == 'confirm'
      end

      def check_args
        if WoD5e.character_types.key(character_type.downcase)
          @character_type = character_type.downcase
          nil
        else
          t('wod5e.invalid_type') << character_type
        end
      end

      def required_args
        [target_name, character_type]
      end

      def handle
        ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          has_sheet = !model.wod5e_sheet.nil?
          if has_sheet && !confirm
            client.emit_failure t('wod5e.sheet_init_exists_warn', name: model.name, type: character_type.capitalize)
            next
          elsif confirm && !has_sheet
            client.emit_failure t('wod5e.sheet_init_nothing_to_confirm', name: model.name)
            next
          end

          model.wod5e_sheet.delete if has_sheet

          sheet = Sheet.create(character: model, character_type: character_type.downcase)
          model.update(wod5e_sheet: sheet)
          client.emit_success t('wod5e.sheet_init_complete', name: model.name, character_type: model.wod5e_sheet.character_type.capitalize)
        end
      end
    end
  end
end
