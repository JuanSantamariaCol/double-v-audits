class AuditEvent
  include Mongoid::Document
  include Mongoid::Timestamps

  # Fields
  field :event_type, type: String      # "client.created", "invoice.read", etc.
  field :entity_type, type: String     # "client" | "invoice" | "system"
  field :entity_id, type: String       # ID of related entity
  field :action, type: String          # "create", "read", "update", "delete", "error"
  field :status, type: String          # "success" | "failed"
  field :metadata, type: Hash          # flexible field for additional context
  field :user_agent, type: String
  field :ip_address, type: String
  field :occurred_at, type: DateTime

  # Validations
  validates :event_type, presence: true
  validates :entity_type, presence: true, inclusion: { in: %w[client invoice system] }
  validates :action, presence: true, inclusion: { in: %w[create read update delete error] }
  validates :status, presence: true, inclusion: { in: %w[success failed] }
  validates :occurred_at, presence: true

  # Indexes for performance
  index({ entity_id: 1 })
  index({ entity_type: 1 })
  index({ event_type: 1 })
  index({ occurred_at: -1 })
  index({ created_at: -1 })
  index({ entity_type: 1, entity_id: 1 })

  # Scopes for common queries
  scope :by_entity, ->(entity_type, entity_id) { where(entity_type: entity_type, entity_id: entity_id) }
  scope :by_entity_type, ->(entity_type) { where(entity_type: entity_type) }
  scope :by_event_type, ->(event_type) { where(event_type: event_type) }
  scope :by_date_range, ->(start_date, end_date) { where(occurred_at: { '$gte': start_date, '$lte': end_date }) }
  scope :recent, -> { order(occurred_at: :desc) }
  scope :successful, -> { where(status: 'success') }
  scope :failed, -> { where(status: 'failed') }

  # Callbacks
  before_validation :set_occurred_at, on: :create

  private

  def set_occurred_at
    self.occurred_at ||= Time.current
  end
end
