# frozen_string_literal: true

module AresMUSH
  module WoD5e
    # Attributes Commands
    class AttributesCmd
      include CommandHandler

      def handle
        attr_dictionary = Global.read_config('wod5e', 'attributes')

        attrs = []

        typeslist = attr_dictionary.map { |attrgrp, _| attrgrp.to_s }

        attrs.push(*(typeslist.map { |type| "%xh#{type}%xn" }))

        typeslist.each do |typename|
          attrs.push(*attr_dictionary[typename].map { |attr| attr['name'] })
        end

        words = 'Lorem ipsum dolor sit amet, consectetur adipiscing elit. Cras ultricies odio turpis, id aliquet risus venenatis eget. Donec accumsan, ex.'.split(' ') # rubocop:disable Layout/LineLength

        (3..5).each { |i| words[i] = "%xr#{words[i]}%xn" }

        template = AresMUSH::BorderedTableTemplate.new words, 20

        client.emit template.render
      end
    end
  end
end
