class Leeds < Parser
  def headers?
    true
  end

  def filename
    'leeds.csv'.freeze
  end

  def parsed_products
    Array.new.tap do |products|
      csv.each_with_index do |row, index|
        options = if row[:colorlist]
          {
            color: row[:colorlist].split(/,|or/)
          }
        else
          {}
        end

        quantities = (1..5).map do |n|
          row[:"priceqtycol#{n}"].to_i
        end

        list_prices = (1..5).map do |n|
          row[:"pricecancol#{n}"]
        end

        image_urls = ["http://media.pcna.com/ms/?/leeds/large/#{row[:photo_feature].gsub('.eps', '')}/en"] if row[:photo_feature]

        product = {
          name: row[:itemname],
          sku: row[:itemno],
          description: row[:description],
          options: options,
          category_names: [row[:category]],
          quantities: quantities,
          list_prices: list_prices,
          discount_codes: row[:priceheadingtype],
          image_urls: image_urls
        }
        puts JSON.pretty_generate(product) if index == 10
        products << product
      end
    end
  end
end
