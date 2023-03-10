require "httparty"

module TossPayments
  HOST = "https://api.tosspayments.com/v1"

  class Config
    attr_accessor :secret_key
  end

  class << self
    def configure
      yield(config) if block_given?
    end

    def config
      @config ||= Config.new
    end

    def payments(payload = {})
      uri = "payments"
      post(uri, payload)
    end

    def confirm(payload = {})
      uri = "confirm"
      post(uri, payload)
    end

    def find(payment_key)
      uri = "payments/#{payment_key}"
      get(uri)
    end

    def find_by_order_id(order_id)
      uri = "payments/orders/#{order_id}"
      get(uri)
    end

    def cancel(payment_key, payload = {})
      uri = "payments/#{payment_key}/cancel"
      post(uri, payload)
    end

    def payments_key_in(payload = {})
      uri = "payments/key-in"
      post(uri, payload)
    end

    def virtual_accounts(payload = {})
      uri = "virtual-accounts"
      post(uri, payload)
    end

    def billing_auth_card(payload = {})
      uri = "billing/authorizations/card"
      post(uri, payload)
    end

    def billing_auth_issue(payload = {})
      uri = "billing/authorizations/issue"
      post(uri, payload)
    end

    def billing(billing_key, payload = {})
      uri = "billing/#{billingKey}"
      post(uri, payload)
    end

    private

    def headers
      { "Authorization": "Basic #{Base64.strict_encode64(config.secret_key)}:" }
    end

    def get(uri, payload = {})
      url = "#{HOST}/#{uri}"
      HTTParty.get(url, headers: headers, body: payload)
    end

    def post
      url = "#{HOST}/#{uri}"
      HTTParty.post(url, headers: headers.merge("Content-Type": "application/json"), body: payload.to_json)
    end
  end
end
