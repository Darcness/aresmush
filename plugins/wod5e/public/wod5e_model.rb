# frozen_string_literal: true

module AresMUSH
  class Sheet < Ohm::Model # :nodoc:
    attribute :character_type

    reference :character, 'AresMUSH::Character'

    collection :attribs, 'AresMUSH::WoD5eAttrib'
    collection :skills, 'AresMUSH::WoD5eSkill'
    collection :all_advantages, 'AresMUSH::WoD5eAdvantage'
    collection :xp_log, 'AresMUSH::WoD5eXPLog'

    attribute :total_experience, type: Ohm::DataTypes::DataType::Float, default: 0.0

    def attributes2
      WoD5eAttrib.find(sheet_id: id)
    end

    def advantages
      WoD5eAdvantage.find(sheet_id: id).select { |a| a.parent_id.nil? }
    end
  end

  class Character < Ohm::Model # :nodoc:
    include ObjectModel

    reference :wod5e_sheet, 'AresMUSH::Sheet'
  end

  # Sheet Attribute
  class WoD5eAttrib < Ohm::Model
    attribute :name
    attribute :value, type: Ohm::DataTypes::DataType::Integer

    reference :sheet, :Sheet
  end

  # Sheet Skill
  class WoD5eSkill < Ohm::Model
    attribute :name
    attribute :value, type: Ohm::DataTypes::DataType::Integer
    attribute :specialties, type: Ohm::DataTypes::DataType::Array, default: []

    reference :sheet, :Sheet
  end

  # Sheet Advantage
  class WoD5eAdvantage < Ohm::Model
    attribute :name
    attribute :value, type: Ohm::DataTypes::DataType::Integer
    attribute :secondary_value, type: Ohm::DataTypes::DataType::Integer

    reference :parent, :WoD5eAdvantage
    reference :sheet, :Sheet

    def children
      WoD5eAdvantage.find(parent_id: id)
    end
  end

  # Sheet XP Expenditure
  class WoD5eXPLog < Ohm::Model
    attribute :value, type: Ohm::DataTypes::DataType::Float
    attribute :note

    reference :sheet, :Sheet
  end
end
