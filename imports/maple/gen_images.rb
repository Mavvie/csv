names = File.read('image_names.txt').split("\n")
skus = File.read('skus.txt').split("\n")
names = names.map do |name|
  {
    raw: name,
    query: name.gsub('_NoBkgd', '').gsub('-DS', ''),
  }
end

shitlist = [
  /CCT/,
  /K1\d+/,
  /\wMB/,
  /SCT/,
  /SN567/,
  /TR\d+/,
]
images = {}

skus.each do |sku|
  query = sku.gsub(/CA$/, '')
  matching = names.select { |n| n[:query].match(/^#{query}\./) }
  if matching.size != 1 && !shitlist.detect{|x| x =~ sku}
    puts "Error: Found #{matching.size} images matching sku #{sku}: #{matching.inspect}"
    exit 1
  end
  images[sku] = "https://s3.amazonaws.com/maple-images/#{matching.first[:raw]}" if matching.first
end

require 'json'
puts JSON.pretty_generate(images)
