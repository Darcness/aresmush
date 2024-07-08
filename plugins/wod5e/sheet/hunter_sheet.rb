# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Hunter Sheet Class
    class HunterSheet < BaseSheet
      #########################################
      # Raw Stats
      def type
        WoD5e.character_types[:Hunter]
      end

      def creed
        @sheet.creed
      end

      def drive
        @sheet.drive
      end

      def desperation
        @sheet.desperation
      end

      def despair?
        !!@sheet.despair?
      end

      def danger
        @sheet.danger
      end

      ##########################################
      # Stat Utilities
      def edge?(edge_name)
        !get_edge(edge_name).nil?
      end

      def perk?(edge_name, perk_name)
        !get_perk(edge_name, perk_name).nil?
      end

      ##########################################
      # 'getters' -- return the entire DB object

      # get an edge
      def get_edge(edge_name)
        edge_name = StatValidators.validate_edge_name(edge_name, type)
        @sheet.edges.to_a.find { |e| e.name.downcase.start_with?(edge_name.downcase) }
      end

      # get a perk
      def get_perk(edge_name, perk_name)
        edge = get_edge(edge_name)
        perk_name = StatValidators.validate_perk_name(perk_name, edge.name, type)
        edge.perks.to_a.find { |p| p.name.downcase.start_with?(perk_name) }
      end

      #########################################
      # utilities

      # creates a hash of the object, used for exporting the values without all the DB fluff
      def to_h
        obj = super

        obj.merge(
          {
            info: { creed:, drive:, despair: despair?, danger:, desperation: },
            edges: @sheet.edges.sort_by(:name, order: 'ALPHA').map { |e| [e.name, e.perks.sort_by(:name, order: 'ALPHA').map(&:name)] }.to_h
          }
        )
      end

      # Initializes a sheet with completely random stats, only to be used for testing.
      def initialize_random_stats
        super

        edge_types = @@type_data.dig(type, 'powers', 'edge_types')

        return if edge_types.nil?

        (1..8).each do |_|
          edge_data = edge_types.sample['edges'].sample

          next if edge?(edge_data['name'])

          edge = WoD5eEdge.create(name: edge_data['name'], sheet: @sheet)

          edge_data['perks'].sample(rand(0..2)).each { |p| WoD5ePerk.create(name: p['name'], edge:, sheet: @sheet) }
        end

        @sheet.update(desperation: rand(0..5))
        @sheet.update(danger: rand(0..5))
        @sheet.update(health: rand(0..5))
        @sheet.update(willpower: rand(0..5))

        nil
      end
    end
  end
end
