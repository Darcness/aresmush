# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Sheet Template
    class SheetTemplate < AresMUSH::ErbTemplateRenderer
      attr_accessor :character, :sheet

      mattr_accessor :attr_dictionary, :skills_dictionary, :type_data

      # rubocop:disable Style/ClassVars
      @@attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
      @@skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
      @@type_data = WoD5e.character_types.map { |_, v| [v, Global.read_config(PLUGIN_NAME, v)] }.to_h
      # rubocop:enable Style/ClassVars

      def initialize(char)
        @character = char
        @sheet = @character.sheet
        super "#{File.dirname(__FILE__)}/sheet.erb"
      end

      def attr_types_list
        attr_dictionary.map { |attrgrp, _| attrgrp.to_s }
      end

      def format_attribute(attribute_name)
        attribute = sheet.get_attribute(attribute_name)

        format_stat_triple(attribute[0], attribute[1])
      end

      def format_skill(skill_name)
        skill = character.wod5e_sheet.skills.select { |s| s.name.downcase == skill_name.downcase }.first
        values = [format_stat_triple(skill_name, skill ? skill.value.to_s : '0')]

        skill&.specialties&.each { |s| values.push(left(" -#{s}", 24)) }

        values
      end

      def format_advantages(advantages, level = 0)
        values = []
        advantages.each do |advantage|
          next unless advantage.respond_to?(:name) &&
                      advantage.respond_to?(:value) &&
                      advantage.respond_to?(:secondary_value) &&
                      advantage.respond_to?(:children)

          left_text = advantage.name
          left_text.prepend("#{' ' * (level * 2)}-") if level.positive?

          right_text = advantage.value.to_s
          right_text = "#{right_text} (#{advantage.secondary_value})" if advantage.secondary_value.positive?

          text_out = format_stat_double(left_text, right_text, [2, right_text.length].max)

          values.push(text_out)
          values.push(*format_advantages(advantage.children.to_a, level + 1)) unless advantage.children.to_a.empty?
        end
        values
      end

      def format_stat_double(left_text, right_text, right_size = 2)
        format_stat_line left_text, right_text, (36 - right_size), right_size
      end

      def format_stat_triple(left_text, right_text, right_size = 2)
        format_stat_line left_text, right_text, (23 - right_size), right_size
      end

      def format_stat_line(left_text, right_text, left_size, right_size)
        format_info_line(left_text, right_text, left_size, right_size, '.')
      end

      def format_info_line(left_text, right_text, left_size, right_size, fill = ' ')
        "#{left(left_text, left_size, fill)} #{right(right_text, right_size)}"
      end

      def format_tree_view(item_list)
        midpoint = (item_list.length / 2) + (item_list.length % 2)

        # We want to keep sub-objects in the same column as their parent.
        # If the first item in the second column is a sub-object (starts with a space),
        # push forward until we find a main-line item.
        midpoint += 1 while midpoint.positive? && midpoint < item_list.length && item_list[midpoint].starts_with?(' ')

        ((0..(midpoint - 1)).map do |i|
          " #{item_list[i]}  #{item_list[i + midpoint]} "
        end).join('%R')
      end

      def format_edges(edges)
        values = []
        edges.each do |edge|
          next unless edge.respond_to?(:name) &&
                      edge.respond_to?(:perks)

          values.push(left(edge.name, 37))
          values.push(*edge.perks.map { |p| left("  -#{p.name}", 37) }) if edge.perks.count.positive?
        end
        values
      end

      def formatted_info_item(item_name, value = nil)
        value ||= character.wod5e_sheet.send item_name
        right_size = [value.to_s.length, 2].max
        format_info_line("#{item_name.capitalize}: ", value, (23 - right_size), right_size)
      end

      def formatted_info_block
        fields = []

        case character.wod5e_sheet.character_type
        when WoD5e.character_types[:Hunter]
          fields.push('creed', 'drive', 'health', 'desperation', 'danger', 'willpower', 'despair')
        end

        (fields.each_with_index.map do |field, idx|
          slot = idx % 3
          left_gutter = "#{' ' if slot.positive?} "

          case field
          when 'name'
            value = character.name
          when 'despair'
            value = character.wod5e_sheet.despair? ? '%xh%xrYES%xn' : 'NO'
          when 'health'
            value = "#{character.wod5e_sheet.health} / #{character.wod5e_sheet.max_health}"
          when 'willpower'
            value = "#{character.wod5e_sheet.willpower} / #{character.wod5e_sheet.max_willpower}"
          end

          right_gutter = slot == 2 && idx != (fields.length - 1) ? '%R' : ''

          "#{left_gutter}#{formatted_info_item(field, value)}#{right_gutter}"
        end).join('')
      end

      def formatted_attributes_list
        ((0..(attr_dictionary[attr_types_list[0]].length - 1)).map do |i|
          " #{(attr_types_list.map { |typename| format_attribute(attr_dictionary[typename][i]['name']) }).join('  ')} "
        end).join('%R')
      end

      def formatted_skills_list
        physicals = []
        skills_dictionary[attr_types_list[0]].each do |phys_skill|
          physicals.push(*format_skill(phys_skill['name']))
        end

        socials = []
        skills_dictionary[attr_types_list[1]].each do |soci_skill|
          socials.push(*format_skill(soci_skill['name']))
        end

        mentals = []
        skills_dictionary[attr_types_list[2]].each do |ment_skill|
          mentals.push(*format_skill(ment_skill['name']))
        end

        ((0..([physicals.length, mentals.length, socials.length].max - 1)).map do |i|
           " #{physicals[i] || left('', 24)}  #{socials[i] || left('', 24)}  #{mentals[i]}"
         end).join('%R')
      end

      def formatted_advantages_list
        advantages = character.wod5e_sheet.advantages.sort_by(&:name)
        return unless advantages.count.positive?

        advantages_out = format_advantages(advantages)

        format_tree_view(advantages_out)
      end

      def formatted_powers_header
        header = WoD5e.character_types.key(character.wod5e_sheet.character_type) && type_data.dig(character.wod5e_sheet.character_type, 'powers', 'name')

        out = center("%xn%xh[ #{header} ]%xn%x!", 78, '-')

        "%x!#{out}%xn"
      end

      def formatted_powers_list
        case character.wod5e_sheet.character_type
        when WoD5e.character_types[:Hunter]
          edges = character.wod5e_sheet.edges.sort_by(:name, order: 'ALPHA')
          return unless edges.count.positive?

          edges_out = format_edges(edges)

          format_tree_view(edges_out)
        end
      end
    end
  end
end
