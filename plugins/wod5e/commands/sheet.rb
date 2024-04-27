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
        AresMUSH::ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          template = AresMUSH::WoD5e::SheetTemplate.new(model)
          client.emit template.render
        end
      end
    end

    # sheet/show command
    class SheetShowCmd
      include AresMUSH::CommandHandler

      attr_accessor :target_name

      def handle
      end
    end
  end
end
