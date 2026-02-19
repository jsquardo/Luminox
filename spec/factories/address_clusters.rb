# frozen_string_literal: true

FactoryBot.define do
  factory :address_cluster do
    cluster_name { "MyString" }
    address_count { 1 }
    cluster_type { "MyString" }
    cluster_score { 1.5 }
  end
end
