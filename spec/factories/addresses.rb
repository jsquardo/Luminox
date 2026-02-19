# frozen_string_literal: true

FactoryBot.define do
  factory :address do
    address { "MyString" }
    label { "MyString" }
    first_seen { "2026-02-18 16:13:10" }
    last_seen { "2026-02-18 16:13:10" }
    transaction_count { 1 }
    total_sent { "9.99" }
    total_received { "9.99" }
    is_contract { false }
    risk_score { 1.5 }
    address_cluster { nil }
  end
end
