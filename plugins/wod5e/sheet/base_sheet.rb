# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class BaseSheet
      # rubocop:disable Style/ClassVars
      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
      @@type_data = WoD5e.character_types.map { |_, v| [v, Global.read_config(PLUGIN_NAME, v)] }.to_h
      # rubocop:enable Style/ClassVars

      def initialize(wod5e_sheet)
        @sheet = wod5e_sheet
      end

      #########################################
      # Raw Stats
      def type
        raise InvalidCharacterTemplateError, 'BaseSheet Object does not have a type!'
      end

      def health
        @sheet.health
      end

      def health_agg
        @sheet.health_agg
      end

      def willpower
        @sheet.willpower
      end

      def willpower_agg
        @sheet.willpower_agg
      end

      def max_health
        get_attribute_value('Stamina') + 3
      end

      def max_willpower
        get_attribute_value('Composure') + get_attribute_value('Resolve')
      end

      ##########################################
      # Stat Utilities

      def get_skill_value(skill_name)
        get_skill(skill_name)&.value || 0
      end

      def get_attribute_value(attribute_name)
        get_attribute(attribute_name).value || 0
      end

      def get_advantage_value(advantage_name)
        get_advantage(advantage_name).value || 0
      end

      ##########################################
      # 'getters' -- return the entire DB object

      def get_attribute(attribute_name)
        @sheet.attribs.to_a.find { |a| a.name.downcase == attribute_name.downcase } ||
          WoD5eAttrib.create(name: StatValidator.validate_attribute_name(attribute_name), sheet: @sheet)
      end

      def get_skill(skill_name)
        @sheet.skills.to_a.find { |s| s.name.downcase == skill_name.downcase } ||
          WoD5eSkill.create(name: StatValidator.validate_skill_name(skill_name), sheet: @sheet)
      end

      def get_specialties(skill_name)
        get_skill(skill_name)&.specialties || []
      end

      def get_advantage(advantage_name)
        seek_advantage(@sheet.advantages, advantage_name)
      end

      #########################################
      # utilities

      # creates a hash of the object, used for exporting the values without all the DB fluff
      def to_h
        {
          type:,
          trackers: {
            health: { superficial: health, agg: health_agg, max: max_health },
            willpower: { superficial: willpower, agg: willpower_agg, max: max_willpower }
          },
          powers_title: @@type_data.dig(type, 'powers', 'name') || '',
          attribs: (@@attr_dictionary.keys.map do |typename|
                      @@attr_dictionary[typename].map { |a| [a['name'], { value: get_attribute_value(a['name']), max: 5 }] }.to_h
                    end).flatten.inject(:merge),
          skills: (@@skills_dictionary.keys.map do |typename|
                     @@skills_dictionary[typename].map do |s|
                       [s['name'], { value: (ski = get_skill(s['name'])).value, max: 5, specialties: ski.specialties }]
                     end.to_h
                   end).inject(:merge),
          advantages: @sheet.advantages.sort_by(&:name).map { |adv| advantage_to_h(adv) }.to_h
        }
      end

      # Initializes a sheet with completely random stats, only to be used for testing.
      def initialize_random_stats
        # Attributes
        @@attr_dictionary.each_value do |attr_group|
          attr_group.each { |attr_name| get_attribute(attr_name['name']).update(value: rand(1..5)) }
        end

        # Skills
        @@skills_dictionary.each_value do |skill_group|
          skill_group.each do |skill_name|
            skill = get_skill(skill_name['name'])
            value = rand(0..5)
            skill.update(value:)
            next unless value.positive?

            specs = [0, rand(-6..3)].min
            next unless specs.positive?

            skill.specialties = (0..specs).map { |_| skill_name['specialties'][rand(0..(skill_name['specialties'].length))] }
          end
        end

        @@type_data[type]['advantages'].sample(8).each do |adv_data|
          set_flaw = (adv_data['flaws'] && rand(-8..1).positive?) || adv_data['levels'].nil?
          levels = (set_flaw ? adv_data['flaws'] : adv_data['levels'])
          level = levels.sample

          adv = WoD5eAdvantage.create(name: level['name'], value: (set_flaw ? (-1 * level['value']) : level['value']), sheet: @sheet)

          next if set_flaw

          adv.update(secondary_value: rand(1..3)) if adv_data['secondary']

          if (traits = adv_data.dig('traits', 'levels'))
            traits.sample(rand(1..traits.length)).each do |t|
              WoD5eAdvantage.create(name: t['name'], value: t['value'], sheet: @sheet, parent: adv)
            end
          end

          if (traits = adv_data.dig('traits', 'flaws')) # rubocop:disable Style/Next
            traits.sample(rand(1..traits.length)).each do |t|
              WoD5eAdvantage.create(name: t['name'], value: (t['value'] * -1), sheet: @sheet, parent: adv)
            end
          end
        end

        nil
      end

      private

      def advantage_to_h(advantage)
        children = advantage.children.sort_by(:name, order: 'ALPHA')&.map { |a| advantage_to_h(a) }.to_h
        [advantage.name, advantage.attributes.merge({ children: })]
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

    # Error for Invalid Class Data in Config
    class InvalidClassDataError < StandardError
      def initialize(msg = 'Invalid Class Data!', exception_type = 'custom')
        @exception_type = exception_type
        super(msg)
      end
    end
  end
end
