class All4One < Parser
  def parsed_products
    Array.new.tap do |products|
      csv.each_slice(5) do |slice|
        4.times do |i|
          offset = 5*i
          product = {}
          product[:information] = {embroidery_location: slice[0][offset + 1]} if slice[0][offset + 1] && slice[0][offset + 1].match(/logo/i)
          product[:supplier] = slice[1][offset + 2]
          product[:sku] = slice[2][offset + 2]
          product[:name] = slice[3][offset + 2]
          product[:net_price] = slice[4][offset + 2]
          mandatory_fields = [:net_price, :sku, :name, :supplier]
          next unless mandatory_fields.all? do |field|
            product[field] && product[field] != ""
          end
          products << product
        end
      end
    end
  end
end
