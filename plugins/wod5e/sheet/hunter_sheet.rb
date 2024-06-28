# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class HunterSheet < BaseSheet
      @@hunter_stats = { # rubocop:disable Style/ClassVars
        Edge: 'edge',
        Perk: 'perk'
      }

      def type
        WoD5e.character_types[:Hunter]
      end

      private

      # Assumes that we have a valid stat of the stat_type.  Should be combined with a StatValidator for public use.
      def _fetch_stat(stat_type, stat_name)
        super
      rescue InvalidStatTypeError
        case stat_type.downcase
        when @@hunter_stats[:Edge]
          sheet.skills.to_a.find { |s| s.name.downcase == stat_name.downcase }&.value || 0
        when @@hunter_stats[:Perk]
          raise StandardError, 'Perks are fetched via get_perk()'
        else
          raise StandardError, "Invalid stat_type: #{stat_type}"
        end
      end

      def _get_stat(stat_type, stat_name)
        base = super

        return base unless base.nil?

        case stat_type.downcase
        when @@hunter_stats[:Edge]
          stat_name = StatValidators.validate_skill_name(stat_name)
        when @@hunter_stats[:Perk]
          raise StandardError, 'Perks are fetched via get_perk()'
        else
          raise StandardError, "Invalid stat_type: #{stat_type}"
        end

        JSON.parse({ name: stat_name, obj: _fetch_stat(stat_type, stat_name) }.to_json, object_class: OpenStruct)
      end
    end
  end
end
