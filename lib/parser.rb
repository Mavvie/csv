require 'csv'

class Parser
  attr_accessor :file
  def initialize(file)
    @file = file
  end

  def csv
    @csv ||= CSV.parse(file.read)
  end

  def parsed_products
    raise NoMethodError, 'Not implemented'
  end

  def to_csv
    raise NoMethodError, 'Not implemented'
  end
end
