module Stripe
  class OAuth
    @options = {
      :site => 'https://connect.stripe.com',
      :authorize_url => '/oauth/authorize',
      :deauthorize_url => '/oauth/deauthorize',
      :token_url => '/oauth/token'
    }

    @client = OAuth2::Client.new(
      ENV['STRIPE_CLIENT_ID'],
      ENV['STRIPE_INSTANCE_SECRET_KEY'],
      @options
    )

    class << self
      attr_accessor :client

      def authorize_url(enterprise_id, options = {})
        options[:enterprise_id] = enterprise_id
        jwt = jwt_encode(options)
        # State param will be passed back after auth
        client.auth_code.authorize_url(state: jwt, scope: 'read_write')
      end

      def request_access_token(auth_code)
        # Fetch and return the account details from Stripe
        client.auth_code.get_token(auth_code).params
      end

      def deauthorize(stripe_user_id)
        client.deauthorize(stripe_user_id).deauthorize_request
      end

      private

      def secret_token
        Openfoodnetwork::Application.config.secret_token
      end

      def jwt_encode(payload)
        JWT.encode(payload, secret_token, 'HS256')
      end

      def jwt_decode(token)
        # Returns the original payload
        JWT.decode(token, secret_token, true, algorithm: 'HS256')[0]
      end
    end
  end
end
