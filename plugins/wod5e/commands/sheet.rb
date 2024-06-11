# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet command
    class SheetCmd
      include AresMUSH::CommandHandler
      attr_accessor :target_name

      def parse_args
        self.target_name = cmd.args ? titlecase_arg(cmd.args) : enactor_name
      end

      def handle
        WoD5e.validate_sheet(target_name, client, enactor) do |model|
          unless target_name.nil? || target_name.strip.empty? || target_name.downcase == 'me' || target_name.downcase == model.name.downcase
            client.emit_failure "You don't have access to see other sheets."
          end

          template = SheetTemplate.new(model)
          client.emit template.render
        end
      end
    end
  end
end
