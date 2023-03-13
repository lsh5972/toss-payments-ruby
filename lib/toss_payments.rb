require "httparty"
require "time"

module TossPayments
  ErrorResponse = Struct.new(
    :response_type,
    :code,
    :message,
    :response,
    keyword_init: true,
  )

  PaymentResponse = Struct.new(
    :response_type,
    :version,
    :payment_key,
    :type,
    :order_id,
    :order_name,
    :m_id,
    :currency,
    :method,
    :total_amount,
    :balanced_amount,
    :status,
    :requested_at,
    :approved_at,
    :use_escrow,
    :last_transaction_key,
    :supplied_amount,
    :vat,
    :culture_expense,
    :tax_free_amount,
    :tax_exemption_amount,
    :cancels, # nullable
    :is_partial_cancelable,
    :card, # nullable
    :virtual_account, # nullable
    :secret, # nullable
    :mobile_phone, # nullable
    :gift_certificate, # nullable
    :transfer, # nullable
    :receipt,
    :checkout,
    :easy_pay, # nullable
    :country, # ISO-3166
    :failure, # nullable
    :cash_receipt, # nullable
    :discount, # nullable
    keyword_init: true,
  )

  BillingResponse = Struct.new(
    :response_type,
    :m_id,
    :customer_key,
    :authenticated_at,
    :method,
    :billing_key,
    :card,
    keyword_init: true,
  )

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
      uri = "payments/confirm"
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
      post(uri, payload, response_type: :billing)
    end

    def billing_auth_issue(payload = {})
      uri = "billing/authorizations/issue"
      post(uri, payload, response_type: :billing)
    end

    def billing(billing_key, payload = {})
      uri = "billing/#{billingKey}"
      post(uri, payload)
    end

    private

    def headers
      { "Authorization": "Basic #{Base64.strict_encode64(config.secret_key + ":")}" }
    end

    def get(uri, payload = {}, response_type: :payment)
      url = "#{HOST}/#{uri}"
      response = HTTParty.get(url, headers: headers, body: payload).parsed_response
      response_to_model(response, response_type: type)
    end

    def post(uri, payload = {}, response_type: :payment)
      url = "#{HOST}/#{uri}"
      response = HTTParty.post(url, headers: headers.merge("Content-Type": "application/json"), body: payload.to_json).parsed_response
      response_to_model(response, response_type: type)
    end

    def response_to_model(response, response_type:)
      return error_response_to_model(response) if response.keys.include?("code")
      return payment_response_to_model(response) if response_type == :payment
      return billing_response_to_model(response) if response_type == :billing
    end

    def error_response_to_model(response)
      ErrorResponse.new(
        response_type: :error,
        code: response["code"],
        message: response["message"],
        data: response["data"],
      )
    end

    def payment_response_to_model(response)
      PaymentResponse.new(
        response_type: :payment,
        version: response["version"],
        payment_key: response["paymentKey"],
        type: response["type"],
        order_id: response["orderId"],
        order_name: response["orderName"],
        m_id: response["mId"],
        currency: response["currency"],
        method: response["method"],
        total_amount: response["totalAmount"],
        balanced_amount: response["balancedAmount"],
        status: response["status"].downcase.to_sym,
        requested_at: Time.parse(response["requestedAt"]),
        approved_at: Time.parse(response["approvedAt"]),
        use_escrow: response["useEscrow"],
        last_transaction_key: response["lastTransactionKey"],
        supplied_amount: response["suppliedAmount"],
        vat: response["vat"],
        culture_expense: response["cultureExpense"],
        tax_free_amount: response["taxFreeAmount"],
        tax_exemption_amount: response["taxExemptionAmount"],
        cancels: response["canceles"]&.map do |cancel|
          {
            cancel_amount: cancel["cancelAmount"],
            cancel_reason: cancel["cancelReason"],
            tax_free_amount: cancel["taxFreeAmount"],
            tax_exemption_amount: cancel["taxExemptionAmount"],
            refundable_amount: cancel["refundableAmount"],
            easy_pay_discount_amount: cancel["easyPayDiscountAmount"],
            canceled_at: Time.parse(cancel["canceledAt"]),
            transaction_key: cancel["transactionKey"],
          }
        end,
        is_partial_cancelable: response["isPartialCancelable"],
        card: response["card"] ? {
          amount: response["card"]["amount"],
          issuer_code: response["card"]["issuerCode"],
          acquirer_code: response["card"]["acquirerCode"],
          number: response["card"]["number"],
          installment_plan_months: response["card"]["installmentPlanMonths"],
          approve_no: response["card"]["approveNo"],
          use_card_point: response["card"]["useCardPoint"],
          card_type: response["card"]["cardType"],
          owner_type: response["card"]["ownerType"],
          acquire_status: response["card"]["acquireStatus"].downcase.to_sym,
          is_interest_free: response["card"]["isInterestFree"],
          interset_payer: response["card"]["intersetPayer"].downcase.to_sym,
        } : nil,
        virtual_account: response["virtualAccount"] ? {
          account_type: response["virtualAccount"]["accountType"],
          account_number: response["virtualAccount"]["accountNumber"],
          bank_code: response["virtualAccount"]["bankCode"],
          customer_name: response["virtualAccount"]["customerName"],
          due_date: Time.parse(response["virtualAccount"]["dueDate"]),
          refund_status: response["virtualAccount"]["refundStatus"].downcase.to_sym,
          expired: response["virtualAccount"]["expired"],
          settlement_status: response["virtualAccount"]["settlementStatus"],
        } : nil,
        secret: response["secret"],
        mobile_phone: response["mobilePhone"] ? {
          customer_mobile_phone: response["mobilePhone"]["customerMobilePhone"],
          settlement_status: response["mobilePhone"]["settlementStatus"],
          receipt_url: response["mobilePhone"]["receiptUrl"],
        } : nil,
        gift_certificate: response["giftCertificate"] ? {
          approve_no: response["giftCertificate"]["approveNo"],
          settlement_status: response["giftCertificate"]["settlementStatus"],
        } : nil,
        transfer: response["transfer"] ? {
          bank_code: response["transfer"]["bankCode"],
          settlement_status: response["transfer"]["settlementStatus"],
        } : nil,
        receipt: response["receipt"] ? {
          url: response["receipt"]["url"],
        } : nil,
        checkout: response["checkout"] ? {
          url: response["checkout"]["url"],
        } : nil,
        easy_pay: response["easyPay"] ? {
          provider: response["easyPay"]["provider"],
          amount: response["easyPay"]["amount"],
          discount_amount: response["easyPay"]["discountAmount"],
        } : nil,
        country: response["country"],
        failure: response["failure"] ? {
          code: response["failure"]["code"],
          message: response["failure"]["message"],
        } : nil,
        cash_receipt: response["cashReceipt"] ? {
          receipt_key: response["cashReceipt"]["receiptKey"],
          type: response["cashReceipt"]["type"],
          amount: response["cashReceipt"]["amount"],
          tax_free_amount: response["cashReceipt"]["taxFreeAmount"],
          issue_number: response["cashReceipt"]["issueNumber"],
          receipt_url: response["cashReceipt"]["receiptUrl"],
        } : nil,
        discount: response["discount"] ? {
          amount: response["discount"]["amount"],
        } : nil,
      )
    end

    def billing_response_to_model(response)
      BillingResponse.new(
        response_type: :billing,
        m_id: response["mId"],
        customer_key: response["customerKey"],
        authenticated_at: Time.parse(response["authenticatedAt"]),
        method: response["method"],
        billing_key: response["billingKey"],
        card: {
          issuer_code: response["card"]["issuerCode"],
          acquirer_code: response["card"]["acquirerCode"],
          number: response["card"]["number"],
          card_type: response["card"]["cardType"],
          owner_type: response["card"]["ownerType"],
        },
      )
    end
  end
end
