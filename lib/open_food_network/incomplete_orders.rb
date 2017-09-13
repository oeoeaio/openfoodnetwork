# Used to find recent incomplete orders for a particular user
# - Orders must be in the 'cart' state
# - Orders must have been created within the last fortnight

module OpenFoodNetwork
  class IncompleteOrders
    # We use user rather than email here because we don't want someone to
    # be able to hijack someone else's order by updating the 'email' field
    def initialize(user)
      @user = user
    end

    # Returns the most recent incomplete order (by created_at)
    # Will return nil if no orders are found
    def last
      orders = if account_invoices.any?
        incomplete_orders
          .where("id NOT IN (?)", account_invoices.map(&:order_id))
      else
        incomplete_orders
      end

      orders.order('created_at DESC').limit(1).first
    end

    private

    def account_invoices
      AccountInvoice.where(user_id: @user.id)
    end

    def incomplete_orders
      Spree::Order
        .where(user_id: @user.id)
        .where(state: 'cart')
        .where('created_at > ?', 14.days.ago)
        .incomplete
    end
  end
end
