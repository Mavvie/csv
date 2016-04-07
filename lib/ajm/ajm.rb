class Ajm < Parser
  def headers?
    true
  end

  def filename
    'ajm.csv'.freeze
  end

  def parsed_products
    Array.new.tap do |products|
      csv.each do |row|
        row[:name] = JSON.dump(JSON.load(row[:name]).split(':').last)
        products << row
      end
    end
  end
end
