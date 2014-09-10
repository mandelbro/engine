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

        def initialize(tag_name, markup, tokens, context)
          @swoop_base = ENV['SWOOP_URL'] || 'https://swoop.up.co'
          @swoop_user = ENV['SWOOP_USER'] || ''
          @swoop_pass = ENV['SWOOP_PASS'] || ''
          super
        end

        # If a URL is passed, prepend the SWOOP base URL before passing the value
        # back to the base class
        def prepare_url(token)
          known_endpoints = /events|people/
          if token.match(::Liquid::QuotedString) and token =~ known_endpoints
            # Prepend base URL for URL values passed in
            token = token.gsub(/['"]/, '')

            # Drop leading slash if present
            token = token.slice(1, token.length) if token[0] == "/"

            # Prepend value and wrap in quotes before passing along
            token = "'#{ @swoop_base }/#{ token }'"
          end

          # Delegate back to base implementation
          super(token)
        end

        def prepare_options(markup)
          @options = {}
          markup.scan(::Liquid::TagAttributes) do |key, value|
            if swoop_terms.include? key
              @options['query'] ||= {}
              @options['query'][key] = value.gsub(/['"]/, '')

            else
              @options[key] = value if key != 'http'
            end
          end

          @options['timeout'] = @options['timeout'].to_f if @options['timeout']
          @expires_in = (@options.delete('expires_in') || 0).to_i

          # Set up Basic Auth
          auth = { username: @swoop_user, password: @swoop_pass }
          @options[:basic_auth] = auth
        end

        def swoop_terms
          swoop_event_terms + swoop_people_terms
        end

        def swoop_event_terms
          %w{
            city nickname country manager region state event_status
            event_type expense_status financial_status facilitator
            venue nearby within since until vertical bootcamp_sponsor
            microsoft_windows_8_event microsoft_bizspark_event google_event
          }
        end

        def swoop_people_terms
          %w{
            roles skills first_name last_name email twitter_handle
            address1 address2 city state_province zip country nearby
            within active region_of_interest country_of_interest languages
          }
        end

      end

      ::Liquid::Template.register_tag('consume_swoop', ConsumeSwoop)
    end
  end
end
