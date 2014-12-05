module Locomotive
  module Liquid
    module Tags
      # Extends the `consume` tag to make Locomotive syndication easier
      # to perform
      #
      # Serves as a Locomotive API proxy, handling things like basic auth, base URLs,
      # and query string building
      #
      # Recognizes the following API endpoints:
      #
      # * "events"
      # * "people"
      #
      # Usage:
      #
      # {% consume_locomotive events from 'events' city: 'Seattle', since: '2014-01-01' %}
      #   {% for event in events %}
      #   {% endfor %}
      # {% endconsume_locomotive %}
      class ConsumeLocomotive < Consume

        Syntax = /(#{::Liquid::VariableSignature}+)\s*from\s*(#{::Liquid::QuotedString}|#{::Liquid::VariableSignature}+)\s*,\s*(#{::Liquid::QuotedString}|#{::Liquid::VariableSignature}+)/

        def initialize(tag_name, markup, tokens, context)
          if markup =~ Syntax
            prepare_base($3)
          end
          super
        end

        def prepare_options(markup)
          @options ||= {}
          @options[:query] = {}
          markup.scan(::Liquid::TagAttributes) do |key, value|
            if key == "query"
              CGI.parse(value.gsub(/['"]/, '')).each do |key, value|
                @options[:query][key.to_sym] = value.first
              end
            else
              @options[key] = value if key != 'http'
            end
          end

          @options['timeout'] = @options['timeout'].to_f if @options['timeout']
          @expires_in = (@options.delete('expires_in') || 0).to_i
        end

        def render context
          if instance_variable_defined? :@base_url_variable_name
            @locomotive_url = context[@base_url_variable_name]
          end
          if instance_variable_defined? :@variable_name
            @url = context[@variable_name]
          end

          render_all_and_cache_it(context)
        end

        def prepare_base token
          if token.match(::Liquid::QuotedString)
            @locomotive_url = token.gsub(/['"]/, '')
          elsif token.match(::Liquid::VariableSignature)
            @base_url_variable_name = token
          else
            raise ::Liquid::SyntaxError.new("Syntax Error in 'consume_locomotive' - Valid syntax: consume <var> from \"<url>\", \"<base>\" [username: value, password: value]")
          end
        end

        def render_url
          # Drop leading slash if present
          rendered_url = @url.slice(1, @url.length) if @url[0] == "/"

          # Prepend value and wrap in quotes before passing along
          "http://#{ @locomotive_url }/locomotive/api/#{ @url }.json"
        end

        def locomotive_auth_token
          return @auth_token unless @auth_token.nil?
          data = {
            query: {
              api_key: ENV['LOCOMOTIVE_API_KEY']
            }
          }
          @auth_token = JSON.parse(Locomotive::Httparty::Webservice.post("http://#{@locomotive_url}/locomotive/api/tokens.json", data).body)["token"]
        end

        def render_all_and_cache_it(context)
          get_options_context(context)
          clear_auth_token

          Rails.cache.fetch(page_fragment_cache_key("#{render_url}?query=#{@options[:query].to_json}"), expires_in: @expires_in, force: @expires_in == 0) do
            self.render_all_without_cache(context)
          end
        end

        def render_all_without_cache(context)
          # Set up auth_token
          @options[:query][:auth_token] ||= locomotive_auth_token

          context.stack do
            begin
              context.scopes.last[@target.to_s] = Locomotive::Httparty::Webservice.consume(render_url, @options.symbolize_keys)
              self.cached_response = context.scopes.last[@target.to_s]
            rescue Timeout::Error
              context.scopes.last[@target.to_s] = self.cached_response
            end

            render_all(@nodelist, context)
          end
        end

        private

          def get_options_context(context)
            @options[:query].each do |key,value|
              @options[:query][key] = context[value] unless context[value].nil?
            end
          end

          def clear_auth_token
            @options[:query].delete(:auth_token)
          end

      end

      ::Liquid::Template.register_tag('consume_locomotive', ConsumeLocomotive)
    end
  end
end
