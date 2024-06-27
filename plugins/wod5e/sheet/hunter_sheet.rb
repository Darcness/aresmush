# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class HunterSheet < BaseSheet
      @@hunter_stats = { # rubocop:disable Style/ClassVars
        Advantage: 'advantage',
        Edge: 'edge',
        Perk: 'perk'
      }

      def type
        WoD5e.character_types.Hunter
      end

      private

      # Assumes that we have a valid stat of the stat_type.  Should be combined with a StatValidator for public use.
      def _fetch_stat(stat_type, stat_name)
        base = super

        return base unless base.nil?

        case stat_type.downcase
        when @@base_stats[:Advantage]
          sheet.attribs.to_a.find { |a| a.name.downcase == stat_name.downcase }&.value || 0
        when @@base_stats[:Edge]
          sheet.skills.to_a.find { |s| s.name.downcase == stat_name.downcase }&.value || 0
        when @@base_stats[:Perk]
          raise StandardError, 'Perks are fetched via get_perk()'
        else
          raise StandardError, "Invalid stat_type: #{stat_type}"
        end
      end

      def _get_stat(stat_type, stat_name)
        base = super

        return base unless base.nil?

        case stat_type.downcase
        when @@base_stats[:Advantage]
          _fetch_stat(stat_type, StatValidators.validate_attribute_name(stat_name))
        when @@base_stats[:Edge]
          _fetch_stat(stat_type, StatValidators.validate_skill_name(stat_name))
        when @@base_stats[:Perk]
          raise StandardError, 'Perks are fetched via get_perk()'
        else
          raise StandardError, "Invalid stat_type: #{stat_type}"
        end
      end
    end
  end
end
