# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet/set command
    class SheetSetCmd
      include AresMUSH::CommandHandler

      attr_accessor :target_name, :stat_type, :stat_name, :main_value, :optional_value

      @@stat_types = { # rubocop:disable Style/ClassVars
        Basic: 'basic',
        Attribute: 'attribute',
        Skill: 'skill',
        Specialty: 'specialty',
        Advantage: 'advantage'
      }

      def parse_args
        args = cmd.parse_args(%r{(?<arg1>[^(=|/)]+)=?(?<arg2>[^/]+)?/?(?<arg3>[^=]+)?=?(?<arg4>[^/]+)?/?(?<arg5>.+)?})
        @target_name = titlecase_arg(args.arg1)
        @stat_type = titlecase_arg(args.arg2)
        @stat_name = titlecase_arg(args.arg3)
        @main_value = titlecase_arg(args.arg4)
        @optional_value = titlecase_arg(args.arg5)
      end

      def check_args
        case stat_type.downcase
        when @@stat_types[:Basic]
          validate_basic_args
        when @@stat_types[:Attribute]
          validate_attribute_args
        when @@stat_types[:Skill]
          validate_skill_args
        when @@stat_types[:Specialty]
          validate_specialty_args
        when @@stat_types[:Advantage]
          validate_advantage_args
        else
          "Invalid type: #{stat_type}"
        end
      end

      def required_args
        [target_name, stat_type, stat_name, main_value]
      end

      def handle
        AresMUSH::ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          case stat_type.downcase
          when @@stat_types[:Basic]
            handle_basic(model)
          when @@stat_types[:Attribute]
            handle_attrib(model)
          when @@stat_types[:Skill]
            handle_skill(model)
          when @@stat_types[:Specialty]
            handle_specialty(model)
          # when @@stat_types[:Advantage]
          #   handle_advantage(model)
          else
            client.emit_failure "Invalid type: #{stat_type} -- We got here past check_args, which is no bueno. Talk to a coder, for realz."
          end
        end
      end

      def validate_numeric_main_value
        begin
          Integer(main_value)
        rescue TypeError, ArgumentError
          "Invalid Value: #{main_value}"
        end
        nil
      end

      def validate_basic_args
        case stat_name.downcase
        when 'type'
          if WoD5e.character_types.key(main_value.downcase)
            @main_value = main_value.downcase
            nil
          else
            "Invalid Type: #{main_value}"
          end
        else
          "Invalid Stat: #{stat_name}"
        end
      end

      def validate_advantage_args
        AresMUSH::ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          if model.character_type.nil? || model.character_type.empty?
            "#{target_name} must have a type specified first"
          elsif !AresMUSH::WoD5e.character_types.key(model.character_type)
            model.update(:character_type, '')
            "#{target_name} has an invalid type! Resetting...."
          end

          type_data = Global.read_config(PLUGIN_NAME, model.character_type)
          if type_data['advantages'].select { |adv| adv['name'].start_with?(stat_name) }.first.nil
            "#{stat_name} is not a valid Advantage for #{model.character_type}"
          end

          validated_main_value = validate_numeric_main_value
          validated_main_value unless validated_main_value.nil?
        end
      end

      def validate_attribute_args
        attr_dictionary = Global.read_config(PLUGIN_NAME, 'attributes')

        attr = attr_dictionary.values.flatten.select { |attr_data| attr_data['name'].start_with?(stat_name) }.first

        if attr.nil?
          "Invalid Attribute #{stat_name}"
        else
          @stat_name = attr['name']
        end

        validate_numeric_main_value
      end

      def validate_skill_name
        skills_dictionary = Global.read_config(PLUGIN_NAME, 'skills')

        skill = skills_dictionary.values.flatten.select { |skill_data| skill_data['name'].start_with?(stat_name) }.first

        if skill.nil?
          "Invalid Skill #{stat_name}"
        else
          @stat_name = skill['name']
          nil
        end
      end

      def validate_skill_args
        validate_skill_name || validate_numeric_main_value
      end

      def validate_specialty_args
        validate_skill_name
      end

      def handle_attrib(model)
        attrib = model.attributes.select { |a| a.name == stat_name }.first

        if attrib
          attrib.update(value: main_value.to_i)
        else
          WoD5eAttribute.create(name: stat_name, value: main_value.to_i, character: model)
        end
        client.emit "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_skill(model)
        skill = model.skills.select { |s| s.name == stat_name }.first

        if skill
          skill.update(value: main_value.to_i)
        else
          AresMUSH::WoD5eSkill.create(name: stat_name, value: main_value.to_i, character: model)
        end
        client.emit "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_specialty(model)
        skill = model.skills.select { |s| s.name == stat_name }.first

        if skill
          new_specialties = skill.specialties || []

          if main_value.starts_with?('!')
            found_pos = new_specialties.index { |x| x == main_value[1, main_value.length] }

            if found_pos.nil?
              client.emit "ERROR: #{target_name} does not have #{main_value} specialty for #{stat_name}!"
              return
            else
              new_specialties.delete_at(found_pos)
            end
          else
            new_specialties.append(main_value)
          end

          skill.update(specialties: new_specialties)
        elsif main_value.starts_with?('!')
          client.emit "ERROR: #{target_name} is missing skill: #{stat_name}!"
          return
        else
          AresMUSH::WoD5eSkill.create(name: stat_name, value: 0,
                                      specialties: [main_value], character: model)
        end

        output = if main.value.starts_with?('!')
                   "#{model.name} removed #{main_value} from #{stat_name} specialties."
                 else
                   "#{model.name} added #{main_value} to #{stat_name} specialties."
                 end

        client.emit_success output
      end

      def handle_basic(model)
        case stat_name.downcase
        when 'type'
          model.update(character_type: main_value)
          client.emit_success "#{model.name} set Type to: #{main_value.capitalize}."
        end
      end

      def handle_advantage(model) end
    end
  end
end
