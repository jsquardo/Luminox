# frozen_string_literal: true

FactoryBot.define do
  factory :transaction do
    tx_hash { "MyString" }
    from_address { "MyString" }
    to_address { "MyString" }
    value { "9.99" }
    gas_price { "9.99" }
    block_number { 1 }
    timestamp { "2026-02-19 21:16:42" }
    token_symbol { "MyString" }
    is_contract_interaction { false }
    anomaly_score { 1.5 }
    is_alerted { false }
  end
end
