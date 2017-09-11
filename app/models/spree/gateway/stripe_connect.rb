require 'stripe/profile_storer'

module Spree
  class Gateway
    class StripeConnect < Gateway
      preference :enterprise_id, :integer

      validate :ensure_enterprise_selected

      attr_accessible :preferred_enterprise_id

      CARD_TYPE_MAPPING = {
        'American Express' => 'american_express',
        'Diners Club' => 'diners_club',
        'Visa' => 'visa'
      }.freeze

      def method_type
        'stripe'
      end

      def provider_class
        ActiveMerchant::Billing::StripeGateway
      end

      def payment_profiles_supported?
        true
      end

      def stripe_account_id
        StripeAccount.find_by_enterprise_id(preferred_enterprise_id).andand.stripe_user_id
      end

      def purchase(money, creditcard, gateway_options)
        provider.purchase(*options_for_purchase_or_auth(money, creditcard, gateway_options))
      end

      def void(response_code, creditcard, gateway_options)
        gateway_options[:stripe_account] = stripe_account_id
        provider.void(response_code, gateway_options)
      end

      def create_profile(payment)
        return unless payment.source.gateway_customer_profile_id.nil?

        profile_storer = Stripe::ProfileStorer.new(payment, provider)
        profile_storer.create_customer_from_token
      end

      private

      # In this gateway, what we call 'secret_key' is the 'login'
      def options
        options = super
        options.merge(:login => Stripe.api_key)
      end

      def options_for_purchase_or_auth(money, creditcard, gateway_options)
        options = {}
        options[:description] = "Spree Order ID: #{gateway_options[:order_id]}"
        options[:currency] = gateway_options[:currency]
        options[:stripe_account] = stripe_account_id

        creditcard = token_from_card_profile_ids(creditcard)

        [money, creditcard, options]
      end

      def update_source!(source)
        source.cc_type = CARD_TYPE_MAPPING[source.cc_type] if CARD_TYPE_MAPPING.include?(source.cc_type)
        source
      end

      def token_from_card_profile_ids(creditcard)
        token_or_card_id = creditcard.gateway_payment_profile_id
        customer = creditcard.gateway_customer_profile_id

        return nil if token_or_card_id.blank?

        # Assume the gateway_payment_profile_id is a token generated by StripeJS
        return token_or_card_id if customer.blank?

        # Assume the gateway_payment_profile_id is a Stripe card_id
        # So generate a new token, using the customer_id and card_id
        tokenize_instance_customer_card(customer, token_or_card_id)
      end

      def tokenize_instance_customer_card(customer, card)
        token = Stripe::Token.create({card: card, customer: customer}, stripe_account: stripe_account_id)
        token.id
      rescue Stripe::StripeError => e
        Rails.logger.error("Stripe Error: #{e}")
        nil
      end

      def ensure_enterprise_selected
        return if preferred_enterprise_id.andand > 0
        errors.add(:stripe_account_owner, I18n.t(:error_required))
      end
    end
  end
end
