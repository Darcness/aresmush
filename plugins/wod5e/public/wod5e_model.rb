# frozen_string_literal: true

module AresMUSH
  class Sheet < Ohm::Model # :nodoc:
    include ObjectModel

    attribute :character_type
    attribute :concept, default: ''
    attribute :ambition, default: ''
    attribute :desire, default: ''
    attribute :health, type: DataType::Integer, default: 0
    attribute :health_agg, type: DataType::Integer, default: 0
    attribute :willpower, type: DataType::Integer, default: 0
    attribute :willpower_agg, type: DataType::Integer, default: 0
    attribute :total_experience, type: DataType::Float, default: 0.0

    reference :character, 'AresMUSH::Character'

    collection :attribs, 'AresMUSH::WoD5eAttrib'
    collection :skills, 'AresMUSH::WoD5eSkill'
    collection :all_advantages, 'AresMUSH::WoD5eAdvantage'
    collection :xp_log, 'AresMUSH::WoD5eXPLog'

    # Hunter stuff
    attribute :creed, default: ''
    attribute :drive, default: ''
    attribute :despair?, type: DataType::Boolean, default: false
    attribute :desperation, type: DataType::Integer, default: 0
    attribute :danger, type: DataType::Integer, default: 0

    collection :edges, 'AresMUSH::WoD5eEdge'
    collection :perks, 'AresMUSH::WoD5ePerk'

    def advantages
      all_advantages.select { |a| a.parent_id.nil? }
    end

    def delete
      attribs.each(&:delete)
      skills.each(&:delete)
      all_advantages.each(&:delete)
      xp_log.each(&:delete)
      edges.each(&:delete)
      perks.each(&:delete)

      super
    end
  end

  class Character < Ohm::Model # :nodoc:
    include ObjectModel

    reference :wod5e_sheet, 'AresMUSH::Sheet'

    def sheet
      return nil if wod5e_sheet.nil?

      return @_sheet unless @_sheet.nil?

      case wod5e_sheet.character_type
      when WoD5e.character_types[:Hunter]
        @_sheet = AresMUSH::WoD5e::HunterSheet.new wod5e_sheet
      else
        raise InvalidCharacterTemplateError
      end

      @_sheet
    end
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
    attribute :secondary_value, type: DataType::Integer, default: 0

    reference :parent, 'AresMUSH::WoD5eAdvantage'
    reference :sheet, 'AresMUSH::Sheet'

    collection :children, 'AresMUSH::WoD5eAdvantage', 'parent'
  end

  # Sheet XP Expenditure
  class WoD5eXPLog < Ohm::Model
    include ObjectModel

    attribute :value, type: DataType::Float
    attribute :note

    reference :sheet, 'AresMUSH::Sheet'
  end
end
