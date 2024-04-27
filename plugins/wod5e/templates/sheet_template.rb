# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Sheet Template
    class SheetTemplate < AresMUSH::ErbTemplateRenderer
      attr_accessor :character, :attr_dictionary, :skills_dictionary

      def initialize(char)
        @character = char
        @attr_dictionary = Global.read_config('wod5e', 'attributes')
        @skills_dictionary = Global.read_config('wod5e', 'skills')
        super "#{File.dirname(__FILE__)}/sheet.erb"
      end

      def attr_types_list
        attr_dictionary.map { |attrgrp, _| attrgrp.to_s }
      end

      def format_attribute(attribute_name)
        attribute = character.attributes.select { |a| a.name.downcase == attribute_name.downcase }.first

        format_stat_triple(attribute_name, attribute ? attribute.value.to_s : '0')
      end

      def format_skill(skill_name)
        skill = character.skills.select { |s| s.name.downcase == skill_name.downcase }.first

        format_stat_triple(skill_name, skill ? skill.value.to_s : '0')
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
        ((0..(skills_dictionary[attr_types_list[0]].length - 1)).map do |i|
           " #{(attr_types_list.map do |typename|
                  format_skill(skills_dictionary[typename][i]['name'])
                end).join('  ')} "
         end).join('%R')
      end
    end
  end
end
