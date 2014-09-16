module Locomotive
  module Wagon
    module Liquid
      module Filters
        module Object

          def json object
            object.reject {|k,v| k == "collections" }.to_json
          end

        end

        ::Liquid::Template.register_filter(Object)

      end
    end
  end
end
