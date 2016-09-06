require 'csv'
require 'json'

class Parser
  PRODUCT_FIELDS = [
    :name, :sku, :parent_sku, :description, :metadata, :category_names, :tag_names,
    :quantities, :list_prices, :discount_codes, :net_prices, :image_url
  ]

  attr_accessor :file
  def initialize
    @file = open_import(filename)
  end

  def open_import(filename, mode = 'r')
    File.open(File.join(File.dirname(__FILE__), '../imports/', filename), mode)
  end

  def csv
    @csv ||= if headers?
      CSV.parse(file.read, headers: true, header_converters: header_converters)
    else
      CSV.parse(file.read)
    end
  end

  def headers?
    false
  end

  def header_converters
    [:symbol]
  end

  def parsed_products
    raise NoMethodError, 'Not implemented'
  end

  def filename
    raise NoMethodError, 'Not implemented'
  end

  def export
    products = parsed_products
    CSV.open(File.join(File.dirname(__FILE__), '../exports/', filename), 'wb') do |out|
      out << PRODUCT_FIELDS
      products.each do |product|
        raise "Invalid keys in: #{product.keys}" if product.keys - PRODUCT_FIELDS != []
        out << PRODUCT_FIELDS.map do |field|
          if !product[field]
            nil
          else
            JSON.dump product[field]
          end
        end
      end
    end
    products.size
  end
end

require_relative 'all4one/all_4_one.rb'
require_relative 'ajm/ajm.rb'
require_relative 'leeds.rb'
require_relative 'maple.rb'
require_relative 'alpha.rb'
