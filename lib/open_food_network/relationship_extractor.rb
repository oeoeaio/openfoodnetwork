require 'csv'
module OpenFoodNetwork
  class RelationshipExtractor
    def self.value_export
      CSV.open("relationships_value-per-month.csv", "wb") do |csv|
        csv << header
        non_self_relationships.each do |relationship|
          csv << value_data_for(relationship.parent, relationship.child)
        end
        shop_enterprises.each do |enterprise|
          csv << value_data_for(enterprise, enterprise)
        end
      end
      nil
    end

    def self.count_export
      CSV.open("relationships_order-count-per-month.csv", "wb") do |csv|
        csv << header
        non_self_relationships.each do |relationship|
          csv << count_data_for(relationship.parent, relationship.child)
        end
        shop_enterprises.each do |enterprise|
          csv << count_data_for(enterprise, enterprise)
        end
      end
      nil
    end

    def self.coordinator_fees_export
      CSV.open("relationships_coordinator-fees-per-month.csv", "wb") do |csv|
        csv << header
        non_self_relationships.each do |relationship|
          csv << coordinator_fee_data_for(relationship.parent, relationship.child)
        end
        shop_enterprises.each do |enterprise|
          csv << coordinator_fee_data_for(enterprise, enterprise)
        end
      end
      nil
    end

    def self.exchange_fees_export
      CSV.open("relationships_exchange-fees-per-month.csv", "wb") do |csv|
        csv << header
        non_self_relationships.each do |relationship|
          csv << exchange_fee_data_for(relationship.parent, relationship.child)
        end
        shop_enterprises.each do |enterprise|
          csv << exchange_fee_data_for(enterprise, enterprise)
        end
      end
      nil
    end

    def self.header
      header = ["From", "To"]
      header += months.map{ |m| m[:name] }
    end

    def self.non_self_relationships
      EnterpriseRelationship.joins(:parent).preload(:parent, :child).where("child_id != parent_id").order('enterprises.name ASC')
    end

    def self.shop_enterprises
      Enterprise.order("name ASC").where(id: Spree::Order.complete.select("DISTINCT distributor_id").pluck(:distributor_id))
    end

    def self.value_data_for(parent, child)
      data = []
      data << parent.name
      data << child.name
      line_items = Spree::LineItem.order(nil).joins(:order, :product).merge(Spree::Order.complete)
        .where('spree_orders.distributor_id = ? AND spree_products.supplier_id = ?', child.id, parent.id)
      order_ids = line_items.select("DISTINCT order_id").map(&:order_id)
      months.each do |month|
        next data << 0 unless order_ids.count > 0
        scoped = line_items.merge(Spree::Order.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop]))
        data << scoped.sum(&:price)
      end
      data
    end

    def self.count_data_for(parent, child)
      data = []
      data << parent.name
      data << child.name
      line_items = Spree::LineItem.order(nil).joins(:order, :product).merge(Spree::Order.complete)
        .where('spree_orders.distributor_id = ? AND spree_products.supplier_id = ?', child.id, parent.id)
      order_ids = line_items.select("DISTINCT order_id").map(&:order_id)
      months.each do |month|
        next data << 0 unless order_ids.count > 0
        scoped = line_items.merge(Spree::Order.where("completed_at >= ? AND completed_at < ?", month[:start], month[:stop]))
        data << scoped.select("DISTINCT order_id").count
      end
      data
    end

    def self.coordinator_fee_data_for(parent, child)
      data = []
      data << parent.name
      data << child.name
      line_items = Spree::LineItem.order(nil).joins(:order, :product).merge(Spree::Order.complete)
        .where('spree_orders.distributor_id = ? AND spree_products.supplier_id = ?', child.id, parent.id)
      order_ids = line_items.select("DISTINCT order_id").map(&:order_id)
      months.each do |month|
        next data << 0 unless order_ids.count > 0
        orders = Spree::Order.joins(order_cycle: :coordinator_fees).where("spree_orders.id IN (?) AND completed_at >= ? AND completed_at < ?", order_ids, month[:start], month[:stop])
        data << orders.select("DISTINCT spree_orders.id").count
      end
      data
    end

    def self.exchange_fee_data_for(parent, child)
      data = []
      data << parent.name
      data << child.name
      line_items = Spree::LineItem.order(nil).joins(:order, :product).merge(Spree::Order.complete)
        .where('spree_orders.distributor_id = ? AND spree_products.supplier_id = ?', child.id, parent.id)
      order_ids = line_items.select("DISTINCT order_id").map(&:order_id)
      months.each do |month|
        next data << 0 unless order_ids.count > 0
        orders = Spree::Order.joins(order_cycle: { exchanges: :exchange_fees}).where('(exchanges.sender_id = ? AND exchanges.incoming = ?) OR (exchanges.receiver_id = ? AND exchanges.incoming = ?)', parent.id, true, child.id, false)
          .where("spree_orders.id IN (?) AND completed_at >= ? AND completed_at < ?", order_ids, month[:start], month[:stop])
        data << orders.select("DISTINCT spree_orders.id").count
      end
      data
    end

    def self.months
      return @months unless @months.nil?
      start = Time.new(2012,01,01)
      stop = start + 1.month
      months = []
      while start <= Time.now.beginning_of_month
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
