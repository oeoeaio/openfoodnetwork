require 'csv'
module OpenFoodNetwork
  class EnterpriseExtractor
    def self.summary_export
      CSV.open("enterprises_summary.csv", "wb") do |csv|
        csv << ["Name", "Type", "Activated?", "Connected Count", "Connected To", "Address", "Joined On"]
        Enterprise.order('name ASC').each do |enterprise|
          csv << summary_data_for(enterprise)
        end
      end
      nil
    end

    def self.payment_method_export
      CSV.open("enterprises_payment-methods.csv", "wb") do |csv|
        header = ["Name", "Payment Method"]
        header += months.map{ |m| m[:name] }
        csv << header
        Enterprise.order('name ASC').each do |enterprise|
          orders = Spree::Order.complete.where(distributor_id: enterprise.id)
          Spree::PaymentMethod.for_distributor(enterprise.id).each do |payment_method|
            scoped = orders.joins(:payments).where('spree_payments.payment_method_id = ?', payment_method.id)
            csv << payment_method_data_for(enterprise, payment_method, scoped)
          end
        end
      end
      nil
    end

    def self.shipping_method_export
      CSV.open("enterprises_shipping-methods.csv", "wb") do |csv|
        header = ["Name", "Shipping Method", "Pickup/Delivery"]
        header += months.map{ |m| m[:name] }
        csv << header
        Enterprise.order('name ASC').each do |enterprise|
          orders = Spree::Order.complete.where(distributor_id: enterprise.id)
          Spree::ShippingMethod.for_distributor(enterprise.id).each do |shipping_method|
            scoped = orders.where('shipping_method_id = ?', shipping_method.id)
            csv << shipping_method_data_for(enterprise, shipping_method, scoped)
          end
        end
      end
      nil
    end

    def self.product_category_export
      CSV.open("enterprises_product-categories-by-month.csv", "wb") do |csv|
        header = ["Name", "Category"]
        header += months.map{ |m| m[:name] }
        csv << header
        Enterprise.order('name ASC').each do |enterprise|
          line_items = Spree::LineItem.joins([:order, product: :primary_taxon]).merge(Spree::Order.complete.where(distributor_id: enterprise.id))
          taxons = Spree::Taxon.where(id: line_items.select("DISTINCT spree_taxons.id AS taxon_id").map(&:taxon_id))
          taxons.each do |taxon|
            scoped = line_items.where('spree_taxons.id = ?', taxon.id)
            csv << product_category_data_for(enterprise, taxon, scoped)
          end
        end
      end
      nil
    end

    def self.total_sales_export
      CSV.open("enterprises_total-sales-by-month.csv", "wb") do |csv|
        header = ["Name"]
        header += months.map{ |m| m[:name] }
        csv << header
        Enterprise.order('name ASC').each do |enterprise|
          orders = Spree::Order.complete.where(distributor_id: enterprise.id)
          csv << total_sales_data_for(enterprise, orders)
        end
      end
      nil
    end

    def self.approx_lead_time_export
      CSV.open("enterprises_approx-lead-time-by-month.csv", "wb") do |csv|
        header = ["Name"]
        header += months.map{ |m| m[:name] }
        csv << header
        Enterprise.order('name ASC').each do |enterprise|
          orders = Spree::Order.joins(:order_cycle).complete
          .where('distributor_id = ? AND completed_at < orders_close_at', enterprise.id)
          csv << approx_lead_time_data_for(enterprise, orders)
        end
      end
      nil
    end

    def self.summary_data_for(enterprise)
      data = []
      data << enterprise.name
      data << enterprise.category
      data << enterprise.activated?
      data << enterprise.relatives.count
      data << enterprise.relatives.map(&:name).join(', ')
      data << enterprise.address.full_address
      data << enterprise.created_at
      data
    end

    def self.payment_method_data_for(enterprise, payment_method, orders)
      data = []
      data << enterprise.name
      data << payment_method.name
      months.each do |month|
        next data << 0 unless orders.count > 0
        scoped = orders.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop])
        data << scoped.count
      end
      data
    end

    def self.shipping_method_data_for(enterprise, shipping_method, orders)
      data = []
      data << enterprise.name
      data << shipping_method.name
      data << (shipping_method.require_ship_address ? "Delivery" : "Pickup")
      order_count = orders.count
      months.each do |month|
        next data << 0 unless order_count > 0
        scoped = orders.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop])
        data << scoped.count
      end
      data
    end

    def self.product_category_data_for(enterprise, taxon, line_items)
      data = []
      data << enterprise.name
      data << taxon.name
      item_count = line_items.count
      months.each do |month|
        next data << 0 unless item_count > 0
        scoped = line_items.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop])
        data << scoped.select("DISTINCT spree_products.id AS product_id").map(&:product_id).uniq.count
      end
      data
    end

    def self.total_sales_data_for(enterprise, orders)
      data = []
      data << enterprise.name
      order_count = orders.count
      months.each do |month|
        next data << 0.to_f unless order_count > 0
        scoped = orders.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop])
        data << scoped.sum(&:total).to_f
      end
      data
    end

    def self.approx_lead_time_data_for(enterprise, orders)
      data = []
      data << enterprise.name
      order_count = orders.count
      months.each do |month|
        next data << "N/A" unless order_count > 0
        scoped = orders.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop])
        next data << "N/A" unless scoped.count > 0
        data << (scoped.sum { |o| (o.order_cycle.orders_close_at - o.completed_at) } / (scoped.count * 1.day)).round(2)
      end
      data
    end

    def self.months
      return @months unless @months.nil?
      start = Time.new(2012,01,01)
      stop = start + 1.month
      months = []
      while start <= Time.new(2017,03,01) # Time.now.beginning_of_month
        month = {}
        month[:name] = start.strftime("%m/%Y")
        month[:start] = start
        month[:stop] = stop
        months << month
        start = stop
        stop = stop + 1.month
      end
      @months = months
    end
  end
end
