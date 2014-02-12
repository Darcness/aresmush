module AresMUSH
  class Game
    key :online_record, Integer    
    
    before_create :initialize_who_record
      
    def initialize_who_record
      Global.logger.debug "Initializing who record."
      @online_record = 0
    end
  end
  
  # TODO: All of this stuff belongs somewhere else.  Here just for testing.
  class Character
    key :status, String

    def is_ic?
      :status == "IC"
    end

    def faction
      "A Faction"
    end
    
    def position
      "Up"
    end
  end
  
end