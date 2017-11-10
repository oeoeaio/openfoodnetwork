module OpenFoodNetwork
  class StandingOrderPaymentUpdater
    def initialize(order)
      @order = order
    end

    def update!
      return unless payment
      ensure_credit_card if card_required?
      payment.update_attributes(amount: @order.outstanding_balance)
    rescue MissingCardError
      send_payment_failure_email
    end

    private

    def payment
      @payment ||= @order.pending_payments.last
    end

    def card_required?
      payment.payment_method.type == Spree::Gateway::StripeConnect
    end

    def ensure_credit_card
      return if payment.source is_a? Spree::CreditCard
      raise MissingCardError unless credit_card.present?
      payment.update_attributes(source: credit_card)
    end

    def credit_card
      @credit_card ||= @order.standing_order.credit_card
    end

    def send_payment_failure_email
      # Spree::OrderMailer.standing_order_email(order.id, 'confirmation', {}).deliver
    end
  end

  class MissingCardError < StandardError; end
end
