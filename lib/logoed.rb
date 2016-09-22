require 'net/http'

class Logoed < Parser
  def headers?
    true
  end

  def header_converters
    []
  end

  def filename
    'logoed.csv'.freeze
  end

  def parsed_products
    Array.new.tap do |products|
      csv.each_with_index do |row, index|
        metadata = {}
        metadata['call for pricing'] = 'Please call for pricing' if row['CADPriceMsg1EN'].present?
        if row["DescriptionEN"].match 'Set up: 40 \(E\)'
          metadata['setup charge'] = "$40 (E)."
        end

        quantities    = (1..10).map { |n| row["CADMinQty#{n}"]  }.select(&:present?).map(&:to_i)
        list_prices   = (1..10).map { |n| row["CADPrice#{n}"]   }.select(&:present?).map(&:to_d)
        net_prices    = list_prices.map { |n| list_prices[n-1] * 0.60 }

        image_url = "https://dl.dropboxusercontent.com/u/8532883/product_pics/#{row['Image']}"

        sku = parent_sku = row['Sku']

        product = {
          name: row['NameEN'],
          sku: sku,
          parent_sku: parent_sku,
          description: row["DescriptionEN"].gsub("\n", "<br/>"),
          metadata: metadata,
          category_names: Array(row['Category1EN']),
          quantities: or_zero(quantities),
          list_prices: or_zero(list_prices),
          net_prices: or_zero(net_prices),
          image_url: image_url
        }

        puts JSON.pretty_generate(product) if index % 10 == 0
        if product[:sku].present?
          products << product
        end
      end
    end.sort_by do |product|
      if product[:sku] == product[:parent_sku]
        -1
      else
        1
      end
    end.select do |product|
      product[:category_names].all? { |n| n.match(/smoke|cheese/i).nil? }
    end
  end

  def or_zero(thing)
    thing.presence || [0]
  end

end
