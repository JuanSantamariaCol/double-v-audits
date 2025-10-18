class AuditEventSerializer
  include JSONAPI::Serializer

  attributes :id,
             :event_type,
             :entity_type,
             :entity_id,
             :action,
             :status,
             :metadata,
             :user_agent,
             :ip_address,
             :occurred_at,
             :created_at,
             :updated_at

  attribute :id do |object|
    object.id.to_s
  end
end
