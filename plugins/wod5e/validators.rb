# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
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
        attr = attr_dictionary.values.flatten.select { |attr_data| attr_data['name'].downcase.start_with?(stat_name.downcase) }.first

        raise StandardError, t('wod5e.validators.invalid_attribute', stat_name:) if attr.nil?

        attr['name']
      end

      # raises StandardError
      def self.validate_skill_name(stat_name)
        skill = skills_dictionary.values.flatten.select { |skill_data| skill_data['name'].downcase.start_with?(stat_name.downcase) }.first

        raise StandardError, t('wod5e.validators.invalid_skill', stat_name:) if skill.nil?

        skill['name']
      end

      # raises InvalidCharacterEmplateError and StandardError
      def self.validate_advantage_name(stat_name, character_type)
        raise InvalidCharacterTemplateError, t('wod5e.validators.invalid_character_type', character_type:) unless WoD5e.character_types.key(character_type) # rubocop:disable Layout/LineLength

        advantage = catch(:advantage) do
          type_data[character_type]['advantages'].each do |adv|
            found = adv['levels']&.find { |inner| inner['name'].downcase.start_with?(stat_name.downcase) }
            throw :advantage, found unless found.nil?

            found = adv['flaws']&.find { |inner| inner['name'].downcase.start_with?(stat_name.downcase) }
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
            found = adv['levels']&.find { |inner| inner['name'].downcase.start_with?(advantage_name.downcase) }
            throw :advantage, adv unless found.nil?

            found = adv['flaws']&.find { |inner| inner['name'].downcase.start_with?(advantage_name.downcase) }
            throw :advantage, adv unless found.nil?
          end

          throw :advantage, nil # we didn't find anything, so throw a nil
        end

        raise StandardError, t('wod5e.validators.missing_advantage', stat_name: advantage_name) if advantage.nil?

        trait = advantage['traits'] &&
                advantage['traits']['levels']&.find { |inner| inner['name'].downcase.start_with?(stat_name.downcase) }

        trait ||= advantage['traits'] && advantage['traits']['flaws']&.find do |inner|
          inner['name'].downcase.start_with?(stat_name.downcase)
        end

        raise StandardError, t('wod5e.validators.invalid_trait', advantage_name:, stat_name:, character_type: character_type.capitalize) if trait.nil? # rubocop:disable Layout/LineLength

        trait['name']
      end

      private_class_method def self.get_edge(edge_name, character_type)
        raise InvalidCharacterTemplateError, t('wod5e.validators.invalid_character_type', character_type:) unless WoD5e.character_types[:Hunter] == character_type.downcase # rubocop:disable Layout/LineLength

        raise StandardError, t('wod5e.validators.invalid_type_data', character_type: :Hunter.to_s) unless type_data.dig(character_type, 'powers', 'edge_types') # rubocop:disable Layout/LineLength

        edge = catch(:edge) do
          type_data[character_type]['powers']['edge_types'].each do |edge_type|
            unless edge_type['edges']&.count&.positive?
              raise StandardError,
                    t('wod5e.validators.invalid_edge_type', edge_type: edge_type['type'])
            end

            found = edge_type['edges'].find do |inner|
              inner['name'].downcase.start_with?(edge_name.downcase)
            end
            throw :edge, found unless found.nil?
          end

          throw :edge, nil
        end

        raise StandardError, t('wod5e.validators.invalid_edge', edge_name:) if edge.nil?

        edge
      end

      # raises InvalidCharacterTemplateError, StandardError
      def self.validate_edge_name(edge_name, character_type)
        edge = get_edge(edge_name, character_type)
        edge['name']
      end

      # raises InvalidCharacterTemplateError, StandardError
      def self.validate_perk_name(perk_name, edge_name, character_type)
        edge = get_edge(edge_name, character_type)

        perk = edge['perks'].find { |p| p['name'].downcase.start_with?(perk_name.downcase) }
        raise StandardError, t('wod5e.validators.invalid_perk', edge_name: edge['name'], perk_name:) if perk.nil?

        perk['name']
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
