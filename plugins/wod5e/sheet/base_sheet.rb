# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class BaseSheet
      @@base_stats = { # rubocop:disable Style/ClassVars
        Attribute: 'attribute',
        Skill: 'skill',
        Advantage: 'advantage'
      }

      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')

      def initialize(wod5e_sheet)
        @sheet = wod5e_sheet
      end

      def type
        raise InvalidCharacterTemplateError, 'BaseSheet Object does not have a type!'
      end

      def get_attribute(attribute_name)
        @sheet.attribs.to_a.find { |a| a.name.downcase == attribute_name.downcase }
      end

      def get_attribute_value(attribute_name)
        get_attribute(attribute_name)&.value || 0
      end

      def get_skill(skill_name)
        @sheet.skills.to_a.find { |s| s.name.downcase == skill_name.downcase }
      end

      def get_skill_value(skill_name)
        get_skill(skill_name)&.value || 0
      end

      def get_specialties(skill_name)
        get_skill(skill_name)&.specialties || []
      end

      def get_advantage(advantage_name)
        seek_advantage(@sheet.advantages, advantage_name)
      end

      def get_advantage_value(advantage_name)
        get_advantage(advantage_name)&.value || 0
      end

      def attributes
        values = []

        @@attr_dictionary.each_key do |attrgrp|
          values.push(*@@attr_dictionary[attrgrp].map { |a| [a['name'], get_advantage_value(a['name'])] })
        end

        values
      end

      private

      def seek_advantage(advantages, target_name)
        catch(:adv) do
          advantages.each do |a|
            found = a.name.downcase.start_with?(target_name)
            throw :adv, a if found

            found = seek_advantage(a.children, target_name)
            throw :adv, found unless found.nil?
          end
          throw :adv, nil
        end
      end

      # Assumes that we have a valid stat of the stat_type.  Should be combined with a StatValidator for public use.
      def _fetch_stat(stat_type, stat_name)
        case stat_type.downcase
        when @@base_stats[:Attribute]
          @sheet.attribs.to_a.find { |a| a.name.downcase == stat_name.downcase }
        when @@base_stats[:Skill]
          @sheet.skills.to_a.find { |s| s.name.downcase == stat_name.downcase }
        else
          raise InvalidStatTypeError
        end
      end

      def _get_stat(stat_type, stat_name)
        case stat_type.downcase
        when @@base_stats[:Attribute]
          stat_name = StatValidators.validate_attribute_name(stat_name)
        when @@base_stats[:Skill]
          stat_name = StatValidators.validate_skill_name(stat_name)
        else
          return nil
        end

        { name: stat_name, obj: _fetch_stat(stat_type, stat_name) }
      end
    end

    # Error for Invalid Stat Type
    class InvalidStatTypeError < StandardError
      def initialize(msg = 'Invalid Stat Type!', exception_type = 'custom')
        @exception_type = exception_type
        super(msg)
      end
    end
  end
end
