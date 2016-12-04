class OrderUploadForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :csv, :headers

  def initialize(file)
    file.open
    @csv = CSV.new(file.read, :headers => true, return_headers: true, :header_converters => :symbol, :converters => [:all])
    @headers = csv.readline.to_hash.values
    file.close
  end

  def valid?
    headers == ["Customer Email", "Product", "Variant", "Quantity", "Shipping Method"]
  end
end
