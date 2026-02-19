# frozen_string_literal: true

FactoryBot.define do
  factory :risk_alert do
    alert_type { "MyString" }
    risk_score { 1.5 }
    description { "MyText" }
    is_read { false }
    related_transaction { nil }
    related_address { "MyString" }
  end
end
