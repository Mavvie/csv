require 'csv'
require 'json'

class Parser
  PRODUCT_FIELDS = [
    :name, :sku, :description, :options, :category_names, :tag_names,
    :quantities, :list_prices, :discount_codes, :net_prices, :image_urls
  ]

  attr_accessor :file
  def initialize
    @file = File.open(File.join(File.dirname(__FILE__), '../imports/', filename))
  end

  def csv
    @csv ||= if headers?
      CSV.parse(file.read, headers: true, header_converters: :symbol)
    else
      CSV.parse(file.read)
    end
  end

  def headers?
    false
  end

  def parsed_products
    raise NoMethodError, 'Not implemented'
  end

  def filename
    raise NoMethodError, 'Not implemented'
  end

  def export
    CSV.open(File.join(File.dirname(__FILE__), '../exports/', filename), 'wb') do |out|
      out << PRODUCT_FIELDS
      parsed_products.each do |product|
        out << PRODUCT_FIELDS.map do |field|
          product[field]
        end
      end
    end
  end
end

require_relative 'all4one/all_4_one.rb'
require_relative 'ajm/ajm.rb'
