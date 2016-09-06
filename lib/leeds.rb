require 'active_support'
require 'active_support/core_ext'

class Leeds < Parser
  COLOR_BLACKLIST = ['Component', 'Case']
  def headers?
    true
  end

  def header_converters
    []
  end

  def filename
    'leeds.csv'.freeze
  end

  def color_map
    @color_map ||= JSON.parse(open_import('leeds_colors.json').read)
  end

  def get_colors
    arr = Array.new.tap do |products|
      csv.each_with_index do |row, index|
        colors = if row['ColorList']
          row['ColorList'].split(/,|\sor\s/).map(&:strip)
        else
          [nil]
        end

        image_headers = ['Feature'] + (1..30).to_a.map(&:to_s)

        color_codes = image_headers.map do |h|
          image_header = "Photo_#{h}"
          row[image_header]
        end.compact.map do |filename|
          filename.match(/#{row['ItemNo']}([^\_]*)\_/).try(:[], 1)
        end.compact

        products << [colors, color_codes] if colors.present? && color_codes.present?
      end
    end
    map = {
      'Aqua' => 'AQ',
      'royal' => 'RYL',
      'Lime green' => 'LM',
      'Lime' => 'LM',
      'Pink and White Stripe' => 'PKWH',
      'Orange and White Stripe' => 'ORWH',
      'Purple and White Stripe' => 'PPWH',
      'Cream' => 'CR',
      'Chrome' => 'CR',
      'Red/White/Blue' => 'RWB',
      'OceanBL' => 'BL',
      'Blue' => 'BL',
      'Coral' => 'CRL'
    }

    colors_to_codes_with_weight = arr.group_by(&:itself).map{|k,v| [k, v.size] }.sort_by{|data| -data[1]}
    50.times do
      colors_to_codes_with_weight.map! do |data|
        # puts "#{data[0][0].join(', ')} \t=> #{data[0][1].join(', ')} \t(#{data[1]})"
        data[0][0].reject!{|color| map.keys.include? color}
        data[0][1].reject!{|code| map.values.include? code}

        if data[0][1].size == 1 && data[0][0].size == 1
          map[data[0][0][0]] ||= data[0][1][0] if data[0][1][0].present?
        end
        data
      end
    end
    map.keys.each do |key|
      map["#{key}/#{key}"] = map[key] + map[key]
    end
    map.keys.combination(2).each do |combination|
      next if combination.any? { |c| c.match("/") }
      new_colors = ["#{combination[0]}/#{combination[1]}", "#{combination[0]} and #{combination[1]}"]
      puts combination[0], map[combination[0]]
      puts combination[1], map[combination[1]]
      new_code = map[combination[0]] + map[combination[1]]
      new_colors.each { |new_color| map[new_color] ||= new_code }
      new_colors = ["#{combination[1]}/#{combination[0]}", "#{combination[1]} and #{combination[0]}"]
      new_code = map[combination[1]] + map[combination[0]]
      new_colors.each { |new_color| map[new_color] ||= new_code }
    end
    f = open_import("leeds_colors.json", 'w')
    f.write JSON.pretty_generate map
    f.close
  end

  def parsed_products
    parents = {}
    arr = Array.new.tap do |products|
      csv.each_with_index do |row, index|
        next unless row['PriceQtyCol1']
        colors = if row['ColorList']
          row['ColorList'].split(/,|\sor\s/).map(&:strip)
        else
          [nil]
        end

        quantities = (1..5).map do |n|
          row["PriceQtyCol#{n}"].to_i
        end

        list_prices = (1..5).map do |n|
          row["PriceCanCol#{n}"]
        end

        net_prices = [list_prices.map(&:to_f).min * 0.6] * list_prices.size

        metadata = {
          material: row['Material'],
          size: row['CatalogSize'],
          packaging: row['PackagingDetails']
        }

        image_headers = ['Feature'] + (1..30).to_a.map(&:to_s)

        colors.each_with_index do |color, index|
          sku = "#{row['ItemNo']}-#{color}"
          if index == 0
            parents[row['ItemNo']] = sku
          end

          image_url = image_headers.detect do |h|
            image_header = "Photo_#{h}"
            next unless row[image_header].present?
            next if COLOR_BLACKLIST.include?(color)
            puts color or next unless color_map[color]
            row[image_header].match(color_map[color])
          end

          image_url &&= "http://media.pcna.com/ms/?/leeds/large/#{row["Photo_#{image_url}"].gsub('.eps', '')}/en"

          products << {
            name: row['ItemName'],
            sku: sku,
            parent_sku: parents[row['ItemNo']],
            description: row['Description'],
            metadata: metadata.merge(color: color),
            category_names: [row['Category']],
            quantities: quantities,
            list_prices: list_prices,
            net_prices: net_prices,
            image_url: image_url
          }
        end
      end
    end
  end
end
