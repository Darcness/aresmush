# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet command
    class SheetCmd
      include AresMUSH::CommandHandler

      def handle
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
