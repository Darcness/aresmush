# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class BaseSheet
      @@base_stats = { # rubocop:disable Style/ClassVars
        Attribute: 'attribute',
        Skill: 'skill'
      }

      def initialize(wod5e_sheet)
        @sheet = wod5e_sheet
      end

      def type
        raise InvalidCharacterTemplateError, 'BaseSheet Object does not have a type!'
      end

      def get_attribute(stat_name)
        _get_stat('attribute', stat_name)
      end

      def get_skill(stat_name)
        _get_stat('skill', stat_name)
      end

      def get_specialties(skill_name)
        _fetch_stat(base_stats[:Skill], skill_name)&.specialties || []
      end

      private

      # Assumes that we have a valid stat of the stat_type.  Should be combined with a StatValidator for public use.
      def _fetch_stat(stat_type, stat_name)
        case stat_type.downcase
        when @@base_stats[:Attribute]
          @sheet.attribs.to_a.find { |a| a.name.downcase == stat_name.downcase }
        when @@base_stats[:Skill]
          @sheet.skills.to_a.find { |s| s.name.downcase == stat_name.downcase }
        end
      end

      def _get_stat(stat_type, stat_name)
        case stat_type.downcase
        when @@base_stats[:Attribute]
          @stat_name = StatValidators.validate_attribute_name(stat_name)
        when @@base_stats[:Skill]
          @stat_name = StatValidators.validate_skill_name(stat_name)
        else
          return nil
        end

        stat = _fetch_stat(stat_type, stat_name)
        Global.logger.debug(stat)
        [stat.name, stat&.value || 0]
      end
    end
  end
end
