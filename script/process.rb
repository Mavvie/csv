require_relative '../lib/parser.rb'
SUPPLIER_MAP = {
  "ajm" => Ajm,
  "leeds" => Leeds,
  "maple" => Maple,
  'alpha' => Alpha,
  'logoed' => Logoed
}

supplier = ARGV.shift
if supplier.nil? || !SUPPLIER_MAP[supplier]
  puts "Invalid supplier"
  exit 1
end

klass = SUPPLIER_MAP[supplier]
puts "Parsing #{klass}"

parser = klass.new

puts "Exported #{parser.filename} (#{parser.export} SKUs)"
