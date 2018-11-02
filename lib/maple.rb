require 'net/http'

class Maple < Parser
  def headers?
    true
  end

  def header_converters
    []
  end

  def filename
    'maple/products.csv'.freeze
  end

  def categories
    @categories ||= CSV.parse(open_import('maple/categories.csv'))[1..-1].inject({}) do |c,r|
      c[r[0]] = r[1] if r[0] && r[1]
      c
    end
  end

  # def canadian
  #   @canadian ||= CSV.parse(open_import('maple/canadian.csv'), headers: true).inject({}) do |c,row|
  #     c[row['MRF Item #']] = {}
  #     row.to_hash.keys.compact.each do |key|
  #       c[row['MRF Item #']][key] = row[key]
  #     end
  #     c
  #   end
  # end

  def images
    @images ||= JSON.parse(open_import('maple/images.json', 'r').read)
  end

  def save_images
    f = open_import('maple/images.json', 'w')
    f.write images.to_json
    f.close
  end

  def parsed_products
    Array.new.tap do |products|
      csv.each_with_index do |row, index|
        metadata = {}
        metadata['dimensions'] = ["Product Dimensions L",	"Product Dimensions W", "Product Dimensions H"].map do |f|
          "#{row[f]}\"" if row[f] && row[f] != ""
        end.compact.join(" x ")
        metadata['imprint details'] = row['Imprint Details']
        metadata['imprint dimensions'] = ['Imprint Dimensions L', 'Imprint Dimensions W'].map do |f|
          "#{row[f]}\"" if row[f] && row[f] != ""
        end.compact.join(" x ")
        metadata['production time'] = row['Production Time']
        metadata['kosher'] = !!(row["Kosher"] && row["Kosher"] != "")
        metadata['new'] = !!(row["New"] && row["New"] != "")
        if row["Setup Charge Applies"] && row["Setup Charge Applies"] != ""
          metadata['setup charge'] = "$50 (C). Exact Reorder Set-Up Charge: $20 (C)."
        end
        metadata['ship weight'] = "#{row['Ship Weight Each']} lbs each; #{row['Weight per Case']} lbs per case of #{row['Units/Case']}"

        list_prices = if row["Min Qty"].to_i == 300
          ["300-599", "600-2399"]
        else
          ["Min -47", "48-95", "96-239", "240-479", "480-959"]
        end.map do |name|
          row[name].to_f
        end.reject { |p| p == 0.0}

        quantities = if row["Min Qty"].to_i == 300
          [300, 600]
        else
          [row["Min Qty"].to_i, 48, 96, 240, 480].uniq
        end[0..(list_prices.size-1)]
        metadata['discount codes'] = "#{list_prices.size}C"
        puts row['MRF Item #']

        # if images[row['MRF Item #']].blank? && !row['MRF Item #'].match('IMC')
        #   image_urls = [
        #     "/u/8532883/maple_images/#{row["MRF Item #"]}_NoBkgd.jpg",
        #     "/u/8532883/maple_images/#{row["MRF Item #"]}_NoBkgd-DS.jpg"
        #   ]
        #
        #   image_url = image_urls.find do |path|
        #     url = URI("https://dl.dropboxusercontent.com")
        #     code = nil
        #
        #     Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        #        response = http.head(path)
        #        code = response.code
        #     end
        #
        #     code.to_i == 200
        #   end
        #
        #   image_url = "https://dl.dropboxusercontent.com" + image_url if image_url
        #   images[row['MRF Item #']] = image_url
        #   save_images
        # end
        image_url = images[row['MRF Item #']]

        parent_sku = row["Default Item #"] || row["MRF Item #"]
        parent_sku = "NPD129" if parent_sku == "SPD129" # Shitty data

        product = {
          name: row["Item Name"],
          sku: row["MRF Item #"],
          parent_sku: parent_sku,
          description: row["Catalog Copy"],
          metadata: metadata,
          category_names: [categories[row["Category"]] || "Individual Packaging"],
          quantities: quantities,
          list_prices: list_prices,
          discount_codes: (row['Mfg Code'].last * list_prices.size rescue nil),
          image_url: image_url
        }

        puts JSON.pretty_generate(product) if index % 10 == 0
        if product[:sku] && product[:sku] != ""
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

end
