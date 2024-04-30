# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # sheet/set command
    class SheetSetCmd
      include AresMUSH::CommandHandler

      attr_accessor :target_name, :stat_type, :stat_name, :main_value, :optional_value

      def parse_args
        args = cmd.parse_args(%r{(?<arg1>[^(=|/)]+)=?(?<arg2>[^/]+)?/?(?<arg3>[^=]+)?=?(?<arg4>[^/]+)?/?(?<arg5>.+)?})
        @target_name = titlecase_arg(args.arg1)
        @stat_type = titlecase_arg(args.arg2)
        @stat_name = titlecase_arg(args.arg3)
        @main_value = titlecase_arg(args.arg4)
        @optional_value = titlecase_arg(args.arg5)
      end

      def required_args
        [target_name, stat_type, stat_name, main_value]
      end

      def handle_attrib(model)
        attrib = model.attributes.select { |a| a.name.downcase == stat_name.downcase }.first

        if attrib
          attrib.update(value: main_value.to_i)
        else
          WoD5eAttribute.create(name: stat_name, value: main_value.to_i, character: model)
        end
        client.emit "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_skill(model)
        skill = model.skills.select { |s| s.name.downcase == stat_name.downcase }.first

        if skill
          skill.update(value: main_value.to_i)
        else
          AresMUSH::WoD5eSkill.create(name: stat_name, value: main_value.to_i, character: model)
        end
        client.emit "#{target_name}'s #{stat_name} #{stat_type} set to #{main_value}."
      end

      def handle_specialty(model)
        skill = model.skills.select { |s| s.name.downcase == stat_name.downcase }.first

        if skill
          new_specialties = skill.specialties || []

          if main_value.starts_with?('!')
            found_pos = new_specialties.index { |x| x.downcase == main_value[1, main_value.length].downcase }

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

        client.emit "#{target_name} #{main_value.starts_with?('!') ? 'removed' : 'added'} #{main_value} #{main_value.starts_with?('!') ? 'from' : 'to'} #{stat_name} specialties." # rubocop:disable Layout/LineLength
      end

      def handle
        AresMUSH::ClassTargetFinder.with_a_character(target_name, client, enactor) do |model|
          case stat_type.downcase
          when 'attribute'
            handle_attrib(model)
          when 'skill'
            handle_skill(model)
          when 'specialty'
            handle_specialty(model)
          end
        end
      end
    end
  end
end
