class SubscriptionEstimator
  def initialize(subscription)
    @subscription = subscription
  end

  def update!
    update_price_estimates
  end

  private

  attr_accessor :subscription

  delegate :subscription_line_items, to: :subscription

  def update_price_estimates
    subscription_line_items.each do |item|
      item.price_estimate =
        price_estimate_for(item.variant, item.price_estimate_was)
    end
  end

  def price_estimate_for(variant, fallback)
    return fallback unless fee_calculator && variant
    fees = fee_calculator.indexed_fees_for(variant)
    (variant.price + fees).to_d
  end

  def fee_calculator
    return @fee_calculator unless @fee_calculator.nil?
    shop, next_oc = subscription.shop, subscription.schedule.andand.current_or_next_order_cycle
    return nil unless shop && next_oc
    @fee_calculator = OpenFoodNetwork::EnterpriseFeeCalculator.new(shop, next_oc)
  end
end
