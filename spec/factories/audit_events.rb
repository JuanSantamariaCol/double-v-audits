FactoryBot.define do
  factory :audit_event do
    event_type { "client.created" }
    entity_type { "client" }
    entity_id { "12345" }
    action { "create" }
    status { "success" }
    metadata { { amount: 1000.50, notes: "Test event" } }
    user_agent { "Mozilla/5.0" }
    ip_address { "192.168.1.1" }
    occurred_at { Time.current }

    trait :invoice_event do
      event_type { "invoice.created" }
      entity_type { "invoice" }
      action { "create" }
    end

    trait :error_event do
      event_type { "error.occurred" }
      entity_type { "system" }
      action { "error" }
      status { "failed" }
    end

    trait :read_event do
      action { "read" }
      event_type { "client.read" }
    end

    trait :update_event do
      action { "update" }
      event_type { "client.updated" }
    end

    trait :delete_event do
      action { "delete" }
      event_type { "client.deleted" }
    end
  end
end
