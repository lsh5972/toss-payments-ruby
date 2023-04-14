require "httparty"
require "time"

module TossPayments
  ErrorResponse = Struct.new(
    :response_type,
    :code,
    :message,
    :data,
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
    :balance_amount,
    :status,
    :requested_at,
    :approved_at, # nullable
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

  BankNames = {
    "39": "경남",
    "34": "광주",
    "S8": "교보증권",
    "12": "단위농협",
    "SE": "대신증권",
    "SK": "메리츠증권",
    "S5": "미래에셋증권",
    "SM": "부국",
    "32": "부산",
    "S3": "삼성증권",
    "45": "새마을",
    "64": "산림",
    "SN": "신영증권",
    "S2": "신한금융투자",
    "88": "신한",
    "48": "신협",
    "27": "씨티",
    "20": "우리",
    "71": "우체국",
    "S0": "유안타증권",
    "SJ": "유진투자증권",
    "50": "저축",
    "37": "전북",
    "35": "제주",
    "90": "카카오",
    "SQ": "카카오페이증권",
    "89": "케이",
    "": "토스머니",
    "92": "토스",
    "ST": "토스증권",
    "SR": "펀드온라인코리아",
    "SH": "하나금융투자",
    "81": "하나",
    "S9": "하이투자증권",
    "S6": "한국투자증권",
    "SG": "한화투자증권",
    "SA": "현대차증권",
    "54": "HSBC",
    "SI": "DB금융투자",
    "31": "대구",
    "03": "기업",
    "06": "국민",
    "S4": "KB증권",
    "02": "산업",
    "SP": "KTB투자증권",
    "SO": "LIG투자",
    "11": "농협",
    "SL": "NH투자증권",
    "23": "SC제일",
    "07": "수협",
    "SD": "SK증권",
  }.as_json

  CardNames = {
    "3K": "기업비씨",
    "46": "광주",
    "71": "롯데",
    "30": "산업",
    "31": "BC",
    "51": "삼성",
    "38": "새마을",
    "41": "신한",
    "62": "신협",
    "36": "씨티",
    "33": "우리",
    "W1": "우리",
    "37": "우체국",
    "39": "저축",
    "35": "전북",
    "42": "제주",
    "15": "카카오뱅크",
    "3A": "케이뱅크",
    "24": "토스뱅크",
    "21": "하나",
    "61": "현대",
    "11": "국민",
    "91": "농협",
    "34": "수협",
    "6D": "다이너스",
    "6I": "디스커버",
    "4M": "마스터",
    "3C": "유니온페이",
    "7A": "AMEX",
    "4J": "JCB",
    "4V": "비자",
  }.as_json

  HOST = "https://api.tosspayments.com/v1"

  class Config
    attr_accessor :secret_key
    attr_accessor :billing_secret_key
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
      post(uri, payload, response_type: :billing, secret_key_type: :billing)
    end

    def billing_auth_issue(payload = {})
      uri = "billing/authorizations/issue"
      post(uri, payload, response_type: :billing, secret_key_type: :billing)
    end

    def billing(billing_key, payload = {})
      uri = "billing/#{billing_key}"
      post(uri, payload, secret_key_type: :billing)
    end

    private

    def headers(secret_key_type: :normal)
      { "Authorization": "Basic #{Base64.strict_encode64((secret_key_type === :billing ? config.billing_secret_key : config.secret_key) + ":")}" }
    end

    def get(uri, payload = {}, response_type: :payment, secret_key_type: :normal)
      url = "#{HOST}/#{uri}"
      response = HTTParty.get(url, headers: headers(secret_key_type: secret_key_type)).parsed_response
      response_to_model(response, response_type: response_type)
    end

    def post(uri, payload = {}, response_type: :payment, secret_key_type: :normal)
      url = "#{HOST}/#{uri}"
      response = HTTParty.post(url, headers: headers(secret_key_type: secret_key_type).merge("Content-Type": "application/json"), body: payload.to_json).parsed_response
      response_to_model(response, response_type: response_type)
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
        balance_amount: response["balanceAmount"],
        status: response["status"]&.downcase&.to_sym,
        requested_at: Time.parse(response["requestedAt"]),
        approved_at: response["approvedAt"] ? Time.parse(response["approvedAt"]) : nil,
        use_escrow: response["useEscrow"],
        last_transaction_key: response["lastTransactionKey"],
        supplied_amount: response["suppliedAmount"],
        vat: response["vat"],
        culture_expense: response["cultureExpense"],
        tax_free_amount: response["taxFreeAmount"],
        tax_exemption_amount: response["taxExemptionAmount"],
        cancels: response["cancels"]&.map do |cancel|
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
          card_name: CardNames[response["card"]["issuerCode"]],
          amount: response["card"]["amount"],
          issuer_code: response["card"]["issuerCode"],
          acquirer_code: response["card"]["acquirerCode"],
          number: response["card"]["number"],
          installment_plan_months: response["card"]["installmentPlanMonths"],
          approve_no: response["card"]["approveNo"],
          use_card_point: response["card"]["useCardPoint"],
          card_type: response["card"]["cardType"],
          owner_type: response["card"]["ownerType"],
          acquire_status: response["card"]["acquireStatus"]&.downcase&.to_sym,
          is_interest_free: response["card"]["isInterestFree"],
          interest_payer: response["card"]["interestPayer"]&.downcase&.to_sym,
        } : nil,
        virtual_account: response["virtualAccount"] ? {
          account_type: response["virtualAccount"]["accountType"],
          account_number: response["virtualAccount"]["accountNumber"],
          bank_name: BankNames[response["virtualAccount"]["bankCode"]],
          bank_code: response["virtualAccount"]["bankCode"],
          customer_name: response["virtualAccount"]["customerName"],
          due_date: Time.parse(response["virtualAccount"]["dueDate"]),
          refund_status: response["virtualAccount"]["refundStatus"]&.downcase&.to_sym,
          expired: response["virtualAccount"]["expired"],
          settlement_status: response["virtualAccount"]["settlementStatus"],
          refund_receive_account: response["virtualAccount"]["refundReceiveAccount"] ? {
            bank_name: BankNames[response["virtualAccount"]["refundReceiveAccount"]["bankCode"]],
            bank_code: response["virtualAccount"]["refundReceiveAccount"]["bankCode"],
            account_number: response["virtualAccount"]["refundReceiveAccount"]["accountNumber"],
            holder_name: response["virtualAccount"]["refundReceiveAccount"]["holderName"],
          } : nil,
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
          card_name: CardNames[response["card"]["issuerCode"]],
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
