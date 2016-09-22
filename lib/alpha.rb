require 'net/http'

class Alpha < Parser
  def headers?
    true
  end

  def header_converters
    []
  end

  def filename
    'alpha/items.csv'.freeze
  end

  def prices
    @prices ||= begin
      CSV.parse(open_import('alpha/retail.csv'), headers: true, header_converters: []).inject({}) do |prices, row|
        prices[row['STYLE']] ||= []
        prices[row['STYLE']] << {group: row['GROUP'], size: row['SIZE'], price: row['RETAIL'].gsub('$', '').to_d}
        prices
      end
    end
  end

  def parsed_products
    @parents = {}
    Array.new.tap do |products|
      csv.each_with_index do |row, index|
        metadata = {}
        metadata[:weight] = row['Weight']
        metadata[:size] = row['Size Name']
        metadata[:style_code] = row['Style Code']

        list_prices = Array(row['Retail Price'])

        quantities = [1]

        image_url = 'https://alphabroder.ca' + row['ProdDetail Image']

        parent_sku = @parents[row["Style Code"]] ||= row['Item Number']

        product = {
          name: row["Description"],
          sku: row["Item Number"],
          parent_sku: parent_sku,
          description: row["Features"].try(:gsub, ';', "\n"),
          metadata: metadata,
          category_names: ['Apparel'],
          quantities: quantities,
          list_prices: list_prices,
          discount_codes: 'A',
          image_url: image_url
        }

        puts JSON.pretty_generate(product) if index % 10 == 0
        products << product if product[:sku].present?
      end
    end
  end

end
