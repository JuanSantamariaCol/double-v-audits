# Clear existing data
puts "Clearing existing audit events..."
AuditEvent.delete_all

puts "Creating sample audit events..."

# Sample client IDs and invoice IDs
client_ids = ["CLI-001", "CLI-002", "CLI-003", "CLI-004", "CLI-005"]
invoice_ids = ["INV-001", "INV-002", "INV-003", "INV-004", "INV-005"]

# Create client-related events
client_ids.each_with_index do |client_id, index|
  # Client created
  AuditEvent.create!(
    event_type: "client.created",
    entity_type: "client",
    entity_id: client_id,
    action: "create",
    status: "success",
    metadata: {
      name: "Client #{index + 1}",
      email: "client#{index + 1}@example.com",
      tax_id: "TAX-#{rand(10000..99999)}"
    },
    user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36",
    ip_address: "192.168.1.#{100 + index}",
    occurred_at: (index + 1).days.ago
  )

  # Client read events
  3.times do |read_index|
    AuditEvent.create!(
      event_type: "client.read",
      entity_type: "client",
      entity_id: client_id,
      action: "read",
      status: "success",
      metadata: {
        accessed_fields: ["name", "email", "tax_id"],
        purpose: "view_details"
      },
      user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      ip_address: "192.168.1.#{110 + read_index}",
      occurred_at: (index + 1).days.ago + (read_index + 1).hours
    )
  end

  # Client update
  if index.even?
    AuditEvent.create!(
      event_type: "client.updated",
      entity_type: "client",
      entity_id: client_id,
      action: "update",
      status: "success",
      metadata: {
        updated_fields: ["email", "phone"],
        previous_email: "old#{index + 1}@example.com",
        new_email: "client#{index + 1}@example.com"
      },
      user_agent: "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      ip_address: "192.168.1.#{120 + index}",
      occurred_at: index.hours.ago
    )
  end
end

# Create invoice-related events
invoice_ids.each_with_index do |invoice_id, index|
  # Invoice created
  AuditEvent.create!(
    event_type: "invoice.created",
    entity_type: "invoice",
    entity_id: invoice_id,
    action: "create",
    status: "success",
    metadata: {
      client_id: client_ids.sample,
      amount: rand(100.00..10000.00).round(2),
      currency: "USD",
      items_count: rand(1..10)
    },
    user_agent: "PostmanRuntime/7.32.0",
    ip_address: "192.168.2.#{100 + index}",
    occurred_at: (index + 2).days.ago
  )

  # Invoice read events
  5.times do |read_index|
    AuditEvent.create!(
      event_type: "invoice.read",
      entity_type: "invoice",
      entity_id: invoice_id,
      action: "read",
      status: "success",
      metadata: {
        accessed_by: "user_#{rand(1..5)}",
        purpose: "review"
      },
      user_agent: "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)",
      ip_address: "192.168.2.#{110 + read_index}",
      occurred_at: (index + 2).days.ago + (read_index + 1).hours
    )
  end

  # Some invoice updates
  if index.odd?
    AuditEvent.create!(
      event_type: "invoice.updated",
      entity_type: "invoice",
      entity_id: invoice_id,
      action: "update",
      status: "success",
      metadata: {
        updated_fields: ["status"],
        previous_status: "draft",
        new_status: "sent"
      },
      user_agent: "curl/7.88.0",
      ip_address: "192.168.2.#{120 + index}",
      occurred_at: index.hours.ago
    )
  end

  # Some invoice deletions
  if index == 4
    AuditEvent.create!(
      event_type: "invoice.deleted",
      entity_type: "invoice",
      entity_id: invoice_id,
      action: "delete",
      status: "success",
      metadata: {
        reason: "duplicate",
        deleted_by: "admin_user"
      },
      user_agent: "Mozilla/5.0 (X11; Linux x86_64)",
      ip_address: "192.168.2.130",
      occurred_at: 1.hour.ago
    )
  end
end

# Create some error events
5.times do |index|
  AuditEvent.create!(
    event_type: "error.occurred",
    entity_type: "system",
    entity_id: "SYS-#{index + 1}",
    action: "error",
    status: "failed",
    metadata: {
      error_type: ["ValidationError", "ConnectionError", "TimeoutError", "AuthenticationError"].sample,
      error_message: "An error occurred during processing",
      stack_trace: "Error stack trace here...",
      severity: ["low", "medium", "high", "critical"].sample
    },
    user_agent: "InternalService/1.0",
    ip_address: "10.0.0.#{10 + index}",
    occurred_at: (index + 1).hours.ago
  )
end

# Create recent activity (last hour)
10.times do
  AuditEvent.create!(
    event_type: ["client.read", "invoice.read", "client.updated"].sample,
    entity_type: ["client", "invoice"].sample,
    entity_id: (client_ids + invoice_ids).sample,
    action: ["read", "update"].sample,
    status: "success",
    metadata: {
      timestamp: Time.current,
      session_id: SecureRandom.uuid
    },
    user_agent: [
      "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
      "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
      "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X)"
    ].sample,
    ip_address: "192.168.3.#{rand(1..255)}",
    occurred_at: rand(1..60).minutes.ago
  )
end

total_events = AuditEvent.count
puts "✓ Created #{total_events} audit events"
puts "  - Client events: #{AuditEvent.where(entity_type: 'client').count}"
puts "  - Invoice events: #{AuditEvent.where(entity_type: 'invoice').count}"
puts "  - System/Error events: #{AuditEvent.where(entity_type: 'system').count}"
puts "  - Successful events: #{AuditEvent.where(status: 'success').count}"
puts "  - Failed events: #{AuditEvent.where(status: 'failed').count}"

puts "\nSeed data created successfully!"
