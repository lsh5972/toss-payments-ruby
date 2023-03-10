require "httparty"
require "time"

module TossPayments
  PaymentResponseData = Struct.new(
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

  BillingResponseData = Struct.new(
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
      post(uri, payload, type: :billing)
    end

    def billing_auth_issue(payload = {})
      uri = "billing/authorizations/issue"
      post(uri, payload, type: :billing)
    end

    def billing(billing_key, payload = {})
      uri = "billing/#{billingKey}"
      post(uri, payload)
    end

    private

    def headers
      { "Authorization": "Basic #{Base64.strict_encode64(config.secret_key)}:" }
    end

    def get(uri, payload = {}, type: :payment)
      url = "#{HOST}/#{uri}"
      response = HTTParty.get(url, headers: headers, body: payload).parsed_response
      {
        code: response["code"],
        message: response["message"],
        data: type == :payment ? payment_response_data_to_model(response["data"]) : billing_response_data_to_model(response["data"]),
      }
    end

    def post(uri, payload = {}, type: :payment)
      url = "#{HOST}/#{uri}"
      response = HTTParty.post(url, headers: headers.merge("Content-Type": "application/json"), body: payload.to_json).parsed_response
      {
        code: response["code"],
        message: response["message"],
        data: type == :payment ? payment_response_data_to_model(response["data"]) : billing_response_data_to_model(response["data"]),
      }
    end

    def payment_response_data_to_model(data)
      return nil if data.nil?
      PaymentResponseData.new(
        version: data["version"],
        payment_key: data["paymentKey"],
        type: data["type"],
        order_id: data["orderId"],
        order_name: data["orderName"],
        m_id: data["mId"],
        currency: data["currency"],
        method: data["method"],
        total_amount: data["totalAmount"],
        balanced_amount: data["balancedAmount"],
        status: data["status"].downcase.to_sym,
        requested_at: Time.parse(data["requestedAt"]),
        approved_at: Time.parse(data["approvedAt"]),
        use_escrow: data["useEscrow"],
        last_transaction_key: data["lastTransactionKey"],
        supplied_amount: data["suppliedAmount"],
        vat: data["vat"],
        culture_expense: data["cultureExpense"],
        tax_free_amount: data["taxFreeAmount"],
        tax_exemption_amount: data["taxExemptionAmount"],
        cancels: data["canceles"]&.map do |cancel|
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
        is_partial_cancelable: data["isPartialCancelable"],
        card: data["card"] ? {
          amount: data["card"]["amount"],
          issuer_code: data["card"]["issuerCode"],
          acquirer_code: data["card"]["acquirerCode"],
          number: data["card"]["number"],
          installment_plan_months: data["card"]["installmentPlanMonths"],
          approve_no: data["card"]["approveNo"],
          use_card_point: data["card"]["useCardPoint"],
          card_type: data["card"]["cardType"],
          owner_type: data["card"]["ownerType"],
          acquire_status: data["card"]["acquireStatus"].downcase.to_sym,
          is_interest_free: data["card"]["isInterestFree"],
          interset_payer: data["card"]["intersetPayer"].downcase.to_sym,
        } : nil,
        virtual_account: data["virtualAccount"] ? {
          account_type: data["virtualAccount"]["accountType"],
          account_number: data["virtualAccount"]["accountNumber"],
          bank_code: data["virtualAccount"]["bankCode"],
          customer_name: data["virtualAccount"]["customerName"],
          due_date: Time.parse(data["virtualAccount"]["dueDate"]),
          refund_status: data["virtualAccount"]["refundStatus"].downcase.to_sym,
          expired: data["virtualAccount"]["expired"],
          settlement_status: data["virtualAccount"]["settlementStatus"],
        } : nil,
        secret: data["secret"],
        mobile_phone: data["mobilePhone"] ? {
          customer_mobile_phone: data["mobilePhone"]["customerMobilePhone"],
          settlement_status: data["mobilePhone"]["settlementStatus"],
          receipt_url: data["mobilePhone"]["receiptUrl"],
        } : nil,
        gift_certificate: data["giftCertificate"] ? {
          approve_no: data["giftCertificate"]["approveNo"],
          settlement_status: data["giftCertificate"]["settlementStatus"],
        } : nil,
        transfer: data["transfer"] ? {
          bank_code: data["transfer"]["bankCode"],
          settlement_status: data["transfer"]["settlementStatus"],
        } : nil,
        receipt: data["receipt"] ? {
          url: data["receipt"]["url"],
        } : nil,
        checkout: data["checkout"] ? {
          url: data["checkout"]["url"],
        } : nil,
        easy_pay: data["easyPay"] ? {
          provider: data["easyPay"]["provider"],
          amount: data["easyPay"]["amount"],
          discount_amount: data["easyPay"]["discountAmount"],
        } : nil,
        country: data["country"],
        failure: data["failure"] ? {
          code: data["failure"]["code"],
          message: data["failure"]["message"],
        } : nil,
        cash_receipt: data["cashReceipt"] ? {
          receipt_key: data["cashReceipt"]["receiptKey"],
          type: data["cashReceipt"]["type"],
          amount: data["cashReceipt"]["amount"],
          tax_free_amount: data["cashReceipt"]["taxFreeAmount"],
          issue_number: data["cashReceipt"]["issueNumber"],
          receipt_url: data["cashReceipt"]["receiptUrl"],
        } : nil,
        discount: data["discount"] ? {
          amount: data["discount"]["amount"],
        } : nil,
      )
    end

    def billing_response_data_to_model(data)
      return nil if data.nil?
      BillingResponseData.new(
        m_id: data["mId"],
        customer_key: data["customerKey"],
        authenticated_at: Time.parse(data["authenticatedAt"]),
        method: data["method"],
        billing_key: data["billingKey"],
        card: {
          issuer_code: data["card"]["issuerCode"],
          acquirer_code: data["card"]["acquirerCode"],
          number: data["card"]["number"],
          card_type: data["card"]["cardType"],
          owner_type: data["card"]["ownerType"],
        },
      )
    end
  end
end
