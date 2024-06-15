# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Validate Stats for sheet names
    class StatValidators
      # rubocop:disable Style/ClassVars
      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
      @@type_data = WoD5e.character_types.map { |_, v| [v, Global.read_config(PLUGIN_NAME, v)] }.to_h
      # rubocop:enable Style/ClassVars

      # raises StandardError
      def self.validate_attribute_name(stat_name)
        attr = attr_dictionary.values.flatten.select { |attr_data| attr_data['name'].start_with?(stat_name) }.first

        raise StandardError, "Invalid Attribute: #{stat_name}" if attr.nil?

        attr['name']
      end

      # raises StandardError
      def self.validate_skill_name(stat_name)
        skill = skills_dictionary.values.flatten.select { |skill_data| skill_data['name'].start_with?(stat_name) }.first

        raise StandardError, "Invalid Skill: #{stat_name}" if skill.nil?

        skill['name']
      end

      # raises InvalidCharacterEmplateError and StandardError
      def self.validate_advantage_name(stat_name, character_type)
        raise InvalidCharacterTemplateError, "Invalid character_type: #{character_type}" unless WoD5e.character_types.key(character_type)

        advantage = type_data['advantages'].select { |adv| adv['name'].start_with?(stat_name) }.first

        raise StandardError, "Invalid Advantage for #{character_type}: #{stat_name}" if advantage.nil?

        advantage['name']
      end
    end

    # Error for Invalid Character Templates (Hunter, Vampire, etc)
    class InvalidCharacterTemplateError < StandardError
      def initialize(msg = 'Invalid Character Type!', exception_type = 'custom')
        @exception_type = exception_type
        super(msg)
      end
    end
  end
end
