# frozen_string_literal: true

module AresMUSH
  module WoD5e
    class Sheet < Ohm::Model # :nodoc:
      include ObjectModel

      attribute :character_type

      reference :character, 'AresMUSH::Character'

      collection :attributes, :WoD5eAttribute
      collection :skills, :WoD5eSkill
      collection :all_advantages, :WoD5eAdvantage
      collection :xp_log, :WoD5eXPLog

      attribute :total_experience, type: DataType::Float, default: 0.0

      def advantages
        WoD5eAdvantage.find(sheet_id: id).select { |a| a.parent_id.nil? }
      end
    end

    class Character < Ohm::Model # :nodoc:
      include ObjectModel

      reference :wod5e_sheet, 'AresMUSH::Sheet'
    end

    # Sheet Attribute
    class WoD5eAttribute < Ohm::Model
      include ObjectModel

      attribute :name
      attribute :value, type: DataType::Integer

      reference :sheet, :Sheet
    end

    # Sheet Skill
    class WoD5eSkill < Ohm::Model
      include ObjectModel

      attribute :name
      attribute :value, type: DataType::Integer
      attribute :specialties, type: DataType::Array, default: []

      reference :sheet, :Sheet
    end

    # Sheet Advantage
    class WoD5eAdvantage < Ohm::Model
      include ObjectModel

      attribute :name
      attribute :value, type: DataType::Integer
      attribute :secondary_value, type: DataType::Integer

      reference :parent, :WoD5eAdvantage
      reference :sheet, :Sheet

      def children
        WoD5eAdvantage.find(parent_id: id)
      end
    end

    # Sheet XP Expenditure
    class WoD5eXPLog < Ohm::Model
      include ObjectModel

      attribute :value, type: DataType::Float
      attribute :note

      reference :sheet, :Sheet
    end
  end
end
