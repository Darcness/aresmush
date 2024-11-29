# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Error for Invalid Character Templates (Hunter, Vampire, etc)
    class InvalidCharacterTemplateError < StandardError
      def initialize(msg = 'Invalid Character Type!', exception_type = 'custom')
        @exception_type = exception_type
        super(msg)
      end
    end
  end
end
