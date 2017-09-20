module OpenFoodNetwork
  class PayPalTransactionFeeApplicator
    PayPalPayment = Struct.new(:amount)

    def initialize(order, payment_method)
      @order = order
      @payment_method = payment_method
    end

    def apply_fees
      @order.adjustments.create(adjustment_attrs, :without_protection => true)
    end

    private

    def adjustment_attrs
      {
        :amount => amount,
        :originator => @payment_method,
        :label => label,
        :mandatory => true,
        :state => "closed"
      }
    end

    def amount
      calculable = PayPalPayment.new(@order.total)
      amount = @payment_method.compute_amount(calculable)
    end

    def label
      I18n.t('payment_method_fee')
    end
  end
end
