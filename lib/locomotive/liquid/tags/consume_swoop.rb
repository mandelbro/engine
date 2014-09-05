module Locomotive
  module Liquid
    module Tags
      # Extends the `consume` tag to make SWOOP syndication easier
      # to perform
      #
      # Serves as a SWOOP API proxy, handling things like basic auth, base URLs,
      # and query string building
      #
      # Recognizes the following API endpoints:
      #
      # * "events"
      # * "people"
      #
      # Usage:
      #
      # {% consume_swoop events from 'events' city: 'Seattle', since: '2014-01-01' %}
      #   {% for event in events %}
      #   {% endfor %}
      # {% endconsume_swoop %}
      class ConsumeSwoop < Consume
      end

      ::Liquid::Template.register_tag('consume_swoop', ConsumeSwoop)
    end
  end
end
