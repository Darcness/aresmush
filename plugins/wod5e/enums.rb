# frozen_string_literal: true

# rubocop:disable Style/ClassVars
module AresMUSH # :nodoc:
  module WoD5e # :nodoc:
    @@character_types = {
      Hunter: 'hunter'
    }

    @@stat_types = {
      Basic: 'basic',
      Attribute: 'attribute',
      Skill: 'skill',
      Advantage: 'advantage',
      # Hunter
      Edge: 'edge',
      Perk: 'perk',
      # Vampire
      Discipline: 'discipline',
      # Werewolf
      Gift: 'gift',
      Rite: 'rite'
    }

    mattr_accessor :character_types, :stat_types
  end
end

# rubocop:enable Style/ClassVars
