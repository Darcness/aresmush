# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Sheet Template
    class SheetTemplate < AresMUSH::ErbTemplateRenderer
      attr_accessor :character, :sheet, :attr_dictionary, :skills_dictionary

      def initialize(char)
        @character = char
        @sheet = @character.wod5e_sheet
        @attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')
        @skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')
        super "#{File.dirname(__FILE__)}/sheet.erb"
      end

      def attr_types_list
        attr_dictionary.map { |attrgrp, _| attrgrp.to_s }
      end

      def format_attribute(attribute_name)
        attribute = sheet.attribs.select { |a| a.name.downcase == attribute_name.downcase }.first

        format_stat_triple(attribute_name, attribute ? attribute.value.to_s : '0')
      end

      def format_skill(skill_name)
        skill = sheet.skills.select { |s| s.name.downcase == skill_name.downcase }.first
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
          # return "#{right_text}|#{advantage.secondary_value.positive?}"

          text_out = format_stat_double(left_text, right_text, [2, right_text.length].max)

          # return "#{right_text}||#{text_out}||#{advantage.children}"

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
        "#{left(left_text, left_size, '.')} #{right(right_text, right_size)}"
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
        advantages = sheet.advantages.sort_by(&:name)
        return unless advantages.count.positive?

        advantages_out = format_advantages(advantages)

        midpoint = (advantages_out.length / 2) + (advantages_out.length % 2)

        # We want to keep sub-objects in the same column as their parent.
        # If the first item in the second column is a sub-object (starts with a space),
        # push forward until we find a main-line item.
        midpoint += 1 while midpoint.positive? && midpoint < advantages_out.length && advantages_out[midpoint].starts_with?(' ')

        ((0..(midpoint - 1)).map do |i|
          " #{advantages_out[i]} #{advantages_out[i + midpoint]} "
        end).join('%R')
      end
    end
  end
end
