# frozen_string_literal: true

module AresMUSH
  class Character < Ohm::Model # :nodoc:
    include ObjectModel

    attribute :character_type

    collection :attributes, 'AresMUSH::WoD5eAttribute'
    collection :skills, 'AresMUSH::WoD5eSkill'
    collection :advantages, 'AresMUSH::WoD5eAdvantage'
    collection :xp_log, 'AresMUSH::WoD5eXPLog'

    attribute :total_experience, type: DataType::Float, default: 0.0
  end

  # Sheet Attribute
  class WoD5eAttribute < Ohm::Model
    include ObjectModel
    attribute :name
    attribute :value, type: DataType::Integer

    reference :character, 'AresMUSH::Character'
  end

  # Sheet Skill
  class WoD5eSkill < Ohm::Model
    include ObjectModel
    attribute :name
    attribute :value, type: DataType::Integer
    attribute :specialties, type: DataType::Array, default: []

    reference :character, 'AresMUSH::Character'
  end

  # Sheet Advantage
  class WoD5eAdvantage < Ohm::Model
    include ObjectModel
    attribute :name
    attribute :value, type: DataType::Integer
    attribute :secondary_value, type: DataType::Integer

    reference :character, 'AresMUSH::Character'
  end

  # Sheet XP Expenditure
  class WoD5eXPLog < Ohm::Model
    include ObjectModel
    attribute :value, type: DataType::Float
    attribute :note

    reference :character, 'AresMUSH::Character'
  end
end
