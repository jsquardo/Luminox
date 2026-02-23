# frozen_string_literal: true

FactoryBot.define do
  factory :address_pattern do
    address { "MyString" }
    pattern_type { "MyString" }
    pattern_data { "" }
    confidence { 1.5 }
    detected_at { "2026-02-20 16:33:01" }
  end
end
