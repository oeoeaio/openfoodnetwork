module OpenFoodNetwork
  class PosData
    def initialize(shop, order_cycle)
      @shop = shop
      @order_cycle = order_cycle
    end

    private

    def addresses
      @addresses ||= Spree::Address.preload(:state, :country).joins(shipments: :order).where(spree_orders: { distributor_id: @shop.id})
    end

    def customers
      @customers ||= Customer.where(enterprise_id: @shop.id)
    end

    def orders
      @orders ||= Spree::Order.preload(payments: :payment_method).complete.where(distributor_id: @shop.id, order_cycle_id: @order_cycle.id)
    end

    def line_items
      @line_items ||= Spree::LineItem.preload(:order, :variant).where(order_id: orders)
    end

    def variants
      @variants ||= Spree::Variant.where(id: line_items.pluck(:variant_id)).preload(:product) | @order_cycle.variants_distributed_by(@shop).preload(:product)
    end

    def products
      @products ||= Spree::Product.preload(:supplier, :taxons, master: :images).joins(:variants).where(spree_variants: { id: variants}).select('DISTINCT spree_products.*')
    end

    def payment_methods
      @payment_methods ||= @shop.payment_methods.where(type: "Spree::PaymentMethod::Check")
    end
  end
end
