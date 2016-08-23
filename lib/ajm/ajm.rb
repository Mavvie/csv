class Ajm < Parser
  def headers?
    true
  end

  def header_converters
    []
  end

  def filename
    'ajm.csv'.freeze
  end

  def parsed_products
    @parents = {}

    Array.new.tap do |products|
      csv.each do |row|
        next if row['StyleCode'].nil? || row['StyleCode'] == ''

        color = row["Colourways"]
        sku = "#{row["StyleCode"]}-#{color}"
        parent_sku = if row["# of Colourways"] && row["# of Colourways"] != ""
          @parents[row["StyleCode"]] = sku
        else
          @parents[row['StyleCode']]
        end

        metadata = {
          color: row["Colourway_En"]
        }

        description = row['Description_En'].gsub("~", "\n")
        imgurl = row['WebLink'].match(/mycolorimg=([^\.]*\.jpg)/i)[1]
        image_url = "http://www.ajmintl.com/images_1/style_images_medium/#{imgurl}"
        list_prices = ['Mp Price', 'CL Price', 'VP Price'].map do |f|
          row[f].gsub(/\$|\s/, "")
        end

        product = {
          name: row["Short_Description_En"].gsub("~", " "),
          sku: sku,
          parent_sku: parent_sku,
          description: description,
          metadata: metadata,
          category_names: ["Clothing"],
          quantities: [1, 144, 576],
          list_prices: list_prices,
          net_prices: [row['Mp Price'].gsub(/\$|\s/, "").to_f/2 * 0.86]*3,
          image_url: image_url
        }

        products << product
      end
    end
  end
end
