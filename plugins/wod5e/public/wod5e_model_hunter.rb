# frozen_string_literal: true

module AresMUSH
  # Edge Model for Hunters
  class WoD5eEdge < Ohm::Model
    include ObjectModel

    attribute :name

    reference :sheet, 'AresMUSH::Sheet'

    collection :perks, 'AresMUSH::WoD5ePerk', 'edge'
  end

  # Perk Model for Hunters
  class WoD5ePerk < Ohm::Model
    include ObjectModel

    attribute :name

    reference :sheet, 'AresMUSH::Sheet'
    reference :edge, 'AresMUSH::WoD5eEdge'
  end
end
