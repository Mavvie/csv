require_relative '../lib/parser.rb'
SUPPLIER_MAP = {
  "ajm" => Ajm,
  "leeds" => Leeds
}

supplier = ARGV.shift
if supplier.nil? || !SUPPLIER_MAP[supplier]
  puts "Invalid supplier"
  exit 1
end

klass = SUPPLIER_MAP[supplier]
puts "Parsing #{klass}"

parser = klass.new
parser.export

puts "Exported #{parser.filename}"
