# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class BaseSheet
      # rubocop:disable Style/ClassVars
      @@base_stats = {
        Attribute: 'attribute',
        Skill: 'skill',
        Advantage: 'advantage'
      }
      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
      @@type_data = WoD5e.character_types.map { |_, v| [v, Global.read_config(PLUGIN_NAME, v)] }.to_h
      # rubocop:enable Style/ClassVars

      def initialize(wod5e_sheet)
        @sheet = wod5e_sheet
      end

      def type
        raise InvalidCharacterTemplateError, 'BaseSheet Object does not have a type!'
      end

      def get_attribute(attribute_name)
        @sheet.attribs.to_a.find { |a| a.name.downcase == attribute_name.downcase } ||
          WoD5eAttrib.create(name: StatValidators.validate_attribute_name(attribute_name), sheet: @sheet)
      end

      def get_attribute_value(attribute_name)
        get_attribute(attribute_name).value || 0
      end

      def get_skill(skill_name)
        @sheet.skills.to_a.find { |s| s.name.downcase == skill_name.downcase } ||
          WoD5eSkill.create(name: StatValidators.validate_skill_name(skill_name), sheet: @sheet)
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
        get_advantage(advantage_name).value || 0
      end

      def to_h
        {
          type:,
          powers_title: @@type_data.dig(type, 'powers', 'name') || '',
          attribs: (@@attr_dictionary.keys.map do |typename|
                      @@attr_dictionary[typename].map { |a| [a['name'], get_attribute_value(a['name'])] }.to_h
                    end).flatten.inject(:merge),
          skills: (@@skills_dictionary.keys.map do |typename|
                     @@skills_dictionary[typename].map do |s|
                       [s['name'], { value: (ski = get_skill(s['name'])).value, specialties: ski.specialties }]
                     end.to_h
                   end).inject(:merge),
          advantages: @sheet.advantages.map { |adv| advantage_to_h(adv) }.to_h
        }
      end

      private

      def advantage_to_h(advantage)
        [advantage.name, advantage.attributes.merge({ children: advantage.children.map { |adv| advantage_to_h(adv) }.to_h })]
      end

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
