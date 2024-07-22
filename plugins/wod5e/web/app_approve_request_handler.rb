# frozen_string_literal: true

module AresMUSH
  module WoD5e
    class AppApproveRequestHandler # rubocop:disable Style/Documentation
      def handle(request)
        enactor = request.enactor
        char = Character.find_one_by_name request.args[:id]
        notes = request.args[:notes]

        error = Website.check_login(request)
        return error if error

        request.log_request

        return { error: t('dispatcher.not_allowed') } unless Chargen.can_approve?(enactor)

        error = Chargen.approve_char(enactor, char, notes)
        return { error: } if error

        {}
      end
    end
  end
end
