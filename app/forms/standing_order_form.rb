class StandingOrderForm
  include ActiveModel::Naming
  include ActiveModel::Conversion
  include ActiveModel::Validations

  attr_accessor :standing_order, :params, :fee_calculator, :order_update_issues

  delegate :orders, :order_cycles, :bill_address, :ship_address, :standing_line_items, to: :standing_order
  delegate :shop, :shop_id, :customer, :customer_id, :begins_at, :ends_at, :proxy_orders, to: :standing_order
  delegate :shipping_method, :shipping_method_id, :payment_method, :payment_method_id, to: :standing_order
  delegate :shipping_method_id_changed?, :shipping_method_id_was, :payment_method_id_changed?, :payment_method_id_was, to: :standing_order

  def initialize(standing_order, params={}, fee_calculator=nil)
    @standing_order = standing_order
    @params = params
    @fee_calculator = fee_calculator
    @order_update_issues = {}
  end

  def save
    standing_order.transaction do
      validate_price_estimates
      standing_order.assign_attributes(params)

      initialise_proxy_orders!
      remove_obsolete_proxy_orders!

      update_initialised_orders

      begin
        standing_order.save!
      rescue ActiveRecord::RecordInvalid
        raise ActiveRecord::Rollback
      end
    end
  end

  def json_errors
    standing_order.errors.messages.inject({}) do |errors, (k,v)|
      errors[k] = v.map{ |msg| standing_order.errors.full_message(k,msg) }
      errors
    end
  end

  private

  def update_initialised_orders
    future_and_undated_orders.each do |order|
      order.assign_attributes(customer_id: customer_id, email: customer.andand.email, distributor_id: shop_id)

      update_shipment_for(order) if shipping_method_id_changed?
      update_payment_for(order) if payment_method_id_changed?

      changed_standing_line_items.each do |sli|
        line_item = order.line_items.find_by_variant_id(sli.variant_id)
        if line_item.quantity == sli.quantity_was
          line_item.update_attributes(quantity: sli.quantity, skip_stock_check: true)
        else
          unless line_item.quantity == sli.quantity
            product_name = "#{line_item.product.name} - #{line_item.full_name}"
            add_order_update_issue(order, product_name)
          end
        end
      end

      new_standing_line_items.each do |sli|
        order.line_items.create(variant_id: sli.variant_id, quantity: sli.quantity, skip_stock_check: true)
      end

      order.line_items.where(variant_id: standing_line_items.select(&:marked_for_destruction?).map(&:variant_id)).destroy_all

      order.save
    end
  end

  def future_and_undated_orders
    return @future_and_undated_orders unless @future_and_undated_orders.nil?
    @future_and_undated_orders = orders.joins(:order_cycle).merge(OrderCycle.not_closed).readonly(false)
  end

  def update_payment_for(order)
    payment = order.payments.with_state('checkout').where(payment_method_id: payment_method_id_was).last
    if payment
      payment.andand.void_transaction!
      order.payments.create(payment_method_id: payment_method_id, amount: order.reload.total)
    else
      unless order.payments.with_state('checkout').where(payment_method_id: payment_method_id).any?
        add_order_update_issue(order, I18n.t('admin.payment_method'))
      end
    end
  end

  def update_shipment_for(order)
    shipment = order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id_was).last
    if shipment
      shipment.update_attributes(shipping_method_id: shipping_method_id)
      order.update_attribute(:shipping_method_id, shipping_method_id)
    else
      unless order.shipments.with_state('pending').where(shipping_method_id: shipping_method_id).any?
        add_order_update_issue(order, I18n.t('admin.shipping_method'))
      end
    end
  end

  def initialise_proxy_orders!
    uninitialised_order_cycle_ids.each do |order_cycle_id|
      proxy_orders << ProxyOrder.new(standing_order: standing_order, order_cycle_id: order_cycle_id)
    end
  end

  def uninitialised_order_cycle_ids
    not_closed_in_range_order_cycles.pluck(:id) - proxy_orders.map(&:order_cycle_id)
  end

  def remove_obsolete_proxy_orders!
    obsolete_proxy_orders.destroy_all
  end

  def obsolete_proxy_orders
    in_range_order_cycle_ids = in_range_order_cycles.pluck(:id)
    return proxy_orders unless in_range_order_cycle_ids.any?
    proxy_orders.where('order_cycle_id NOT IN (?)', in_range_order_cycle_ids)
  end

  def not_closed_in_range_order_cycles
    in_range_order_cycles.merge(OrderCycle.not_closed)
  end

  def in_range_order_cycles
    order_cycles.where('orders_close_at >= ? AND orders_close_at <= ?', begins_at, ends_at || 100.years.from_now)
  end

  def changed_standing_line_items
    standing_line_items.select{ |sli| sli.changed? && sli.persisted? }
  end

  def new_standing_line_items
    standing_line_items.select(&:new_record?)
  end

  def validate_price_estimates
    item_attributes = params[:standing_line_items_attributes]
    return unless item_attributes.present?
    if fee_calculator
      item_attributes.each do |item_attrs|
        if variant = Spree::Variant.find_by_id(item_attrs[:variant_id])
          item_attrs[:price_estimate] = price_estimate_for(variant)
        else
          item_attrs.delete(:price_estimate)
        end
      end
    else
      item_attributes.each { |item_attrs| item_attrs.delete(:price_estimate) }
    end
  end

  def price_estimate_for(variant)
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end

  def add_order_update_issue(order, issue)
    order_update_issues[order.id] ||= []
    order_update_issues[order.id] << issue
  end
end