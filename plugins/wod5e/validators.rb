# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Validate Stats for sheet names
    class StatValidators
      mattr_accessor :attr_dictionary, :skills_dictionary, :type_data

      # rubocop:disable Style/ClassVars
      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
      @@type_data = WoD5e.character_types.map { |_, v| [v, Global.read_config(PLUGIN_NAME, v)] }.to_h
      # rubocop:enable Style/ClassVars

      # raises StandardError
      def self.validate_attribute_name(stat_name)
        attr = attr_dictionary.values.flatten.select { |attr_data| attr_data['name'].start_with?(stat_name) }.first

        raise StandardError, t('wod5e.validators.invalid_attribute', stat_name:) if attr.nil?

        attr['name']
      end

      # raises StandardError
      def self.validate_skill_name(stat_name)
        skill = skills_dictionary.values.flatten.select { |skill_data| skill_data['name'].start_with?(stat_name) }.first

        raise StandardError, t('wod5e.validators.invalid_skill', stat_name:) if skill.nil?

        skill['name']
      end

      # raises InvalidCharacterEmplateError and StandardError
      def self.validate_advantage_name(stat_name, character_type)
        raise InvalidCharacterTemplateError, t('wod5e.validators.invalid_character_type', character_type:) unless WoD5e.character_types.key(character_type) # rubocop:disable Layout/LineLength

        advantage = catch(:advantage) do
          type_data[character_type]['advantages'].each do |adv|
            found = adv['levels']&.find { |inner| inner['name'].start_with?(stat_name) }
            throw :advantage, found unless found.nil?

            found = adv['flaws']&.find { |inner| inner['name'].start_with?(stat_name) }
            throw :advantage, found unless found.nil?
          end

          throw :advantage, nil # we didn't find anything, so throw a nil
        end

        raise StandardError, t('wod5e.validators.invalid_advantage', stat_name:, character_type: character_type.capitalize) if advantage.nil? # rubocop:disable Layout/LineLength

        advantage['name']
      end

      def self.validate_trait_name(advantage_name, stat_name, character_type)
        advantage_name = validate_advantage_name(advantage_name, character_type)

        advantage = catch(:advantage) do
          type_data[character_type]['advantages'].each do |adv|
            found = adv['levels']&.find { |inner| inner['name'].start_with?(advantage_name) }
            throw :advantage, adv unless found.nil?

            found = adv['flaws']&.find { |inner| inner['name'].start_with?(advantage_name) }
            throw :advantage, adv unless found.nil?
          end

          throw :advantage, nil # we didn't find anything, so throw a nil
        end

        raise StandardError, t('wod5e.validators.missing_advantage', stat_name: advantage_name) if advantage.nil?

        trait = advantage['traits'] &&
                advantage['traits']['levels']&.find { |inner| inner['name'].start_with?(stat_name) }

        trait ||= advantage['traits'] && advantage['traits']['flaws']&.find { |inner| inner['name'].start_with?(stat_name) }

        raise StandardError, t('wod5e.validators.invalid_trait', advantage_name:, stat_name:, character_type: character_type.capitalize) if trait.nil? # rubocop:disable Layout/LineLength

        trait['name']
      end

      # raises InvalidCharacterTemplateError, StandardError
      def self.validate_edge_name(edge_name)
        raise InvalidCharacterTemplateError, t('wod5e.validators.invalid_character_type', character_type:) unless WoD5e.character_types.key(character_type) # rubocop:disable Layout/LineLength

        raise StandardError, 'Invalid Type Data for Hunter!' unless type_data[:Hunter]['powers'] && type_data[:Hunter]['powers']['edge_types'] # rubocop:disable Layout/LineLength
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
