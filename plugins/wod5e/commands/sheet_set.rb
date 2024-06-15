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
        WoD5e.validate_sheet(target_name, enactor, client) do |model|
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
        @main_value = Integer(main_value)
        nil
      rescue TypeError, ArgumentError
        "Invalid Value: #{main_value}"
      end

      def validate_basic_args
        case stat_name.downcase
        when 'type'
          return "Invalid Type: #{main_value}" unless WoD5e.character_types.key(main_value.downcase)

          @main_value = main_value.downcase
        else
          "Invalid Stat: #{stat_name}"
        end
      end

      def validate_attribute_args
        @stat_name = AresMUSH::WoD5e::StatValidators.validate_attribute_name(stat_name)
        validate_numeric_main_value
      rescue StandardError => e
        e.message
      end

      def validate_skill_args
        @stat_name = StatValidators.validate_skill_name(stat_name)
        validate_numeric_main_value
      rescue StandardError => e
        e.message
      end

      def validate_specialty_args
        @stat_name = StatValidators.validate_skill_name(stat_name)
      rescue StandardError => e
        e.message
      end

      def validate_advantage_args
        ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          if model.wod5e_sheet.character_type.nil? || model.wod5e_sheet.character_type.empty?
            "#{target_name} must have a type specified first"
          elsif !WoD5e.character_types.key(model.wod5e_sheet.character_type)
            model.wod5e_sheet.update(:character_type, '')
            "#{target_name} has an invalid type! Resetting...."
          end

          # Expected Syntax: <AdvantageName>[ (<Note>)] -- ex: Safe House (Apartment 1) OR Resources
          # Step 1, find the note, strip it out.:
          unless (note_start = stat_name.index('(')).nil?
            note = stat_name[(note_start + 1)..]
            note = note[0..-2] if note.end_with?(')')
            @stat_name = stat_name[0, (note_start - 1)].strip
          end

          # Step 2, check the Advantage name
          begin
            @stat_name = StatValidators.validate_advantage_name(stat_name, model.wod5e_sheet.character_type)
          rescue StandardError => e
            return e.message
          end

          # Step 3, put it all back together again.
          @stat_name = "#{stat_name} (#{note})" unless note.nil?

          validated_main_value = validate_numeric_main_value
          validated_main_value unless validated_main_value.nil?
        end
      end

      def handle_attrib(model)
        attrib = model.wod5e_sheet.attributes.select { |a| a.name == stat_name }.first

        if attrib
          attrib.update(value: main_value.to_i)
        else
          WoD5eAttrib.create(name: stat_name, value: main_value.to_i, sheet: model.wod5e_sheet)
        end
        client.emit_success "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_skill(model)
        skill = model.wod5e_sheet.skills.select { |s| s.name == stat_name }.first

        if skill
          skill.update(value: main_value.to_i)
        else
          WoD5eSkill.create(name: stat_name, value: main_value.to_i, sheet: model.wod5e_sheet)
        end
        client.emit_success "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_specialty(model)
        skill = model.wod5e_sheet.skills.select { |s| s.name == stat_name }.first

        if skill
          new_specialties = skill.specialties || []

          if main_value.starts_with?('!')
            found_pos = new_specialties.index { |x| x == main_value[1, main_value.length] }
            new_specialties.map(&:name)

            if found_pos.nil?
              client.emit_failure "#{target_name} does not have #{main_value} specialty for #{stat_name}!"
              return
            else
              new_specialties.delete_at(found_pos)
            end
          else
            new_specialties.append(main_value)
          end

          skill.update(specialties: new_specialties)
        elsif main_value.starts_with?('!')
          client.emit_failure "#{target_name} is missing skill: #{stat_name}!"
          return
        else
          WoD5eSkill.create(name: stat_name,
                            value: 0,
                            specialties: [main_value],
                            sheet: model.wod5e_sheet)
        end

        output = if main.value.starts_with?('!')
                   "#{model.wod5e_sheet.name} removed #{main_value} from #{stat_name} specialties."
                 else
                   "#{model.wod5e_sheet.name} added #{main_value} to #{stat_name} specialties."
                 end

        client.emit_success output
      end

      def handle_basic(model)
        case stat_name.downcase
        when 'type'
          model.wod5e_sheet.update(character_type: main_value)
          client.emit_success "#{model.wod5e_sheet.name} set Type to: #{main_value.capitalize}."
        end
      end

      def handle_advantage(model) end
    end
  end
end
