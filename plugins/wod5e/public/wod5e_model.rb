# frozen_string_literal: true

module AresMUSH
  class Sheet < Ohm::Model # :nodoc:
    include ObjectModel

    attribute :character_type

    reference :character, 'AresMUSH::Character'

    collection :attribs, 'AresMUSH::WoD5eAttrib'
    collection :skills, 'AresMUSH::WoD5eSkill'
    collection :all_advantages, 'AresMUSH::WoD5eAdvantage'
    collection :xp_log, 'AresMUSH::WoD5eXPLog'

    attribute :total_experience, type: DataType::Float, default: 0.0

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
    include ObjectModel

    attribute :name
    attribute :value, type: DataType::Integer

    reference :sheet, 'AresMUSH::Sheet'
  end

  # Sheet Skill
  class WoD5eSkill < Ohm::Model
    include ObjectModel

    attribute :name
    attribute :value, type: DataType::Integer
    attribute :specialties, type: DataType::Array, default: []

    reference :sheet, 'AresMUSH::Sheet'
  end

  # Sheet Advantage
  class WoD5eAdvantage < Ohm::Model
    include ObjectModel

    attribute :name
    attribute :value, type: DataType::Integer
    attribute :secondary_value, type: DataType::Integer

    reference :parent, :WoD5eAdvantage
    reference :sheet, 'AresMUSH::Sheet'

    def children
      WoD5eAdvantage.find(parent_id: id)
    end
  end

  # Sheet XP Expenditure
  class WoD5eXPLog < Ohm::Model
    include ObjectModel

    attribute :value, type: DataType::Float
    attribute :note

    reference :sheet, 'AresMUSH::Sheet'
  end
end
