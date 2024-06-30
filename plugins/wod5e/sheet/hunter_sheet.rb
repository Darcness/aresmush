# frozen_string_literal: true

module AresMUSH
  module WoD5e # :nodoc:
    # Base Sheet Class, meant to be inherited.
    class HunterSheet < BaseSheet
      @@hunter_stats = { # rubocop:disable Style/ClassVars
        Edge: 'edge',
        Perk: 'perk'
      }

      def type
        WoD5e.character_types[:Hunter]
      end

      def get_edge(edge_name)
        edge_name = StatValidators.validate_edge_name(edge_name, type)
        @sheet.edges.to_a.find { |e| e.name.downcase.start_with?(edge_name.downcase) }
      end

      def has_edge?(edge_name) # rubocop:disable Naming/PredicateName
        get_edge(edge_name).nil?
      end

      def get_perk(edge_name, perk_name)
        edge = get_edge(edge_name)
        perk_name = StatValidators.validate_perk_name(perk_name, edge.name, type)
        edge.perks.to_a.find { |p| p.name.downcase.start_with?(perk_name) }
      end

      def has_perk?(edge_name, perk_name) # rubocop:disable Naming/PredicateName
        get_perk(edge_name, perk_name).nil?
      end

      def to_h
        obj = super

        obj.merge(
          {
            edges: @sheet.edges.map { |e| [e.name, e.perks.map(&:name)] }.to_h
          }
        )
      end
    end
  end
end
