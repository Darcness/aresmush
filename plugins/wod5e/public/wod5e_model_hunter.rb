module AresMUSH
    class WoD5eEdge < Ohm::Model
        include ObjectModel

        attribute :name

        reference :sheet, 'AresMUSH::Sheet'

        collection :perks, 'AresMUSH::WoD5ePerk', 'edge'
    end

    class WoD5ePerk < Ohm::Model
        include ObjectModel

        attribute :name

        reference :sheet, 'AresMUSH::Sheet'
        reference :edge, 'AresMUSH::WoD5eEdge'
    end
end