names = File.read('image_names.txt').split("\n")
skus = File.read('skus.txt').split("\n")

images = {}

skus.each do |sku|
  query = sku.gsub(/CA$/, '')
  matching = names.select { |n| n.match(/^#{query}/) }
  images[sku] = "https://s3.amazonaws.com/maple-images/#{matching.first}" if matching.first
end

require 'json'
puts JSON.pretty_generate(images)
