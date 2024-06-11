# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet/show command
    class SheetShowCmd
      include AresMUSH::CommandHandler
      attr_accessor :target_name

      def parse_args
        self.target_name = titlecase_arg(cmd.args)
      end

      def handle
        WoD5e.validate_sheet(target_name, client, enactor) do |target|
          ClassTargetFinder.with_a_character(enactor_name, client, enactor) do |model|
            template = SheetTemplate.new(model)
            Login.emit_ooc_if_logged_in(model, template.render)
            client.emit_success "Sharing your sheet with #{target.name}"
          end
        end
      end
    end
  end
end
