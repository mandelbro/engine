module Locomotive
  module Liquid
    module Filters
      module Object

        def json object
          object.reject {|k,v| k == "collections" }.to_json
        end

        def parse_json string
          JSON.parse(string.to_s)
        end

        def order_by_date object, field, direction = 'asc'

          object.sort do |a, b|
            a_date = parse_date_time(a[field].to_s || 0).to_i
            b_date = parse_date_time(b[field].to_s || 0).to_i
            if direction == 'asc'
              a_date <=> b_date
            else
              a_date <=> b_date
            end
          end
        end

        def since object, field, time
          object.select do |item|
            item_date = parse_date_time(item[field].to_s || 0).to_i
            item_date >= time.to_i
          end
        end

        def only_with object, field
          object.reject do |item|
            item[field].nil? || item[field].empty?
          end
        end

      end

      ::Liquid::Template.register_filter(Object)

    end
  end
end
