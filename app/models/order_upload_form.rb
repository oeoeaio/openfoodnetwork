class OrderUploadForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :csv, :headers, :user, :shop, :order_cycle, :errors

  def initialize(file, user, shop, order_cycle)
    @user, @shop, @order_cycle = user, shop, order_cycle
    @errors = { headers: [], customers: [] }
    file.open
    @csv = CSV.new(file.read, :headers => true, return_headers: true, :header_converters => :symbol, :converters => [:all])
    @headers = csv.readline.to_hash.values
    file.close
  end

  def process!
    return errors[:headers] << t(:invalid_headers) unless headers == ["Customer Email", "Product", "Variant", "Quantity", "Shipping Method"]
    ActiveRecord::Base.transaction do
      csv.each do |line|
        Spree::Order.new(attrs_from(line))
      end
      raise ActiveRecord::Rollback if errors.values.map(&:any?).any?
    end
  end

  def customers_by_email
    return @customers_by_email unless @customers_by_email.nil?
    @customers_by_email = Customer.of(shop).each_with_object({}) do |customer, hash|
      hash[customer.email] = customer
    end
  end

  def attrs_from(line)
    email = line[:customer_email]
    customer = customers_by_email[email]
    shipping_method = shipping_methods_by_name[line[:shipping_method]]
  end
end
