require 'rails_helper'

RSpec.describe AuditEvent, type: :model do
  describe 'validations' do
    it 'validates presence of event_type' do
      audit_event = build(:audit_event, event_type: nil)
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:event_type]).to include("can't be blank")
    end

    it 'validates presence of entity_type' do
      audit_event = build(:audit_event, entity_type: nil)
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:entity_type]).to include("can't be blank")
    end

    it 'validates presence of action' do
      audit_event = build(:audit_event, action: nil)
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:action]).to include("can't be blank")
    end

    it 'validates presence of status' do
      audit_event = build(:audit_event, status: nil)
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:status]).to include("can't be blank")
    end

    it 'validates presence of occurred_at after callback' do
      audit_event = AuditEvent.new(
        event_type: 'test.event',
        entity_type: 'client',
        action: 'create',
        status: 'success'
      )
      # The callback sets occurred_at before validation
      audit_event.valid?
      expect(audit_event.occurred_at).to be_present
    end

    it 'validates entity_type inclusion' do
      audit_event = build(:audit_event, entity_type: 'invalid')
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:entity_type]).to include('is not included in the list')
    end

    it 'validates action inclusion' do
      audit_event = build(:audit_event, action: 'invalid')
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:action]).to include('is not included in the list')
    end

    it 'validates status inclusion' do
      audit_event = build(:audit_event, status: 'invalid')
      expect(audit_event).not_to be_valid
      expect(audit_event.errors[:status]).to include('is not included in the list')
    end

    it 'is valid with valid attributes' do
      audit_event = build(:audit_event)
      expect(audit_event).to be_valid
    end
  end

  describe 'fields' do
    it 'has the correct fields' do
      audit_event = create(:audit_event)
      expect(audit_event).to respond_to(:event_type)
      expect(audit_event).to respond_to(:entity_type)
      expect(audit_event).to respond_to(:entity_id)
      expect(audit_event).to respond_to(:action)
      expect(audit_event).to respond_to(:status)
      expect(audit_event).to respond_to(:metadata)
      expect(audit_event).to respond_to(:user_agent)
      expect(audit_event).to respond_to(:ip_address)
      expect(audit_event).to respond_to(:occurred_at)
    end
  end

  describe 'scopes' do
    let!(:client_event) { create(:audit_event, entity_type: 'client', entity_id: '123') }
    let!(:invoice_event) { create(:audit_event, :invoice_event, entity_id: '456') }
    let!(:error_event) { create(:audit_event, :error_event) }
    let!(:old_event) { create(:audit_event, occurred_at: 2.days.ago) }

    describe '.by_entity' do
      it 'returns events for a specific entity' do
        results = AuditEvent.by_entity('client', '123')
        expect(results).to include(client_event)
        expect(results).not_to include(invoice_event)
      end
    end

    describe '.by_entity_type' do
      it 'returns events for a specific entity type' do
        results = AuditEvent.by_entity_type('client')
        expect(results).to include(client_event)
        expect(results).not_to include(invoice_event)
      end
    end

    describe '.by_event_type' do
      it 'returns events for a specific event type' do
        results = AuditEvent.by_event_type('invoice.created')
        expect(results).to include(invoice_event)
        expect(results).not_to include(client_event)
      end
    end

    describe '.by_date_range' do
      it 'returns events within a date range' do
        start_date = 1.day.ago
        end_date = Time.current
        results = AuditEvent.by_date_range(start_date, end_date)
        expect(results).to include(client_event, invoice_event, error_event)
        expect(results).not_to include(old_event)
      end
    end

    describe '.recent' do
      it 'returns events ordered by occurred_at descending' do
        results = AuditEvent.recent.to_a
        expect(results.first.occurred_at).to be > results.last.occurred_at
      end
    end

    describe '.successful' do
      it 'returns only successful events' do
        results = AuditEvent.successful
        expect(results).to include(client_event, invoice_event)
        expect(results).not_to include(error_event)
      end
    end

    describe '.failed' do
      it 'returns only failed events' do
        results = AuditEvent.failed
        expect(results).to include(error_event)
        expect(results).not_to include(client_event)
      end
    end
  end

  describe 'callbacks' do
    describe '#set_occurred_at' do
      it 'sets occurred_at to current time if not provided' do
        audit_event = AuditEvent.new(
          event_type: 'test.event',
          entity_type: 'client',
          action: 'create',
          status: 'success'
        )
        audit_event.save
        expect(audit_event.occurred_at).to be_present
        expect(audit_event.occurred_at.to_i).to be_within(2).of(Time.current.to_i)
      end

      it 'does not override occurred_at if provided' do
        custom_time = 1.hour.ago
        audit_event = create(:audit_event, occurred_at: custom_time)
        expect(audit_event.occurred_at.to_i).to be_within(2).of(custom_time.to_i)
      end
    end
  end

  describe 'indexes' do
    it 'has the correct indexes defined' do
      index_keys = AuditEvent.index_specifications.map { |spec| spec.key.stringify_keys }

      expect(index_keys).to include('entity_id' => 1)
      expect(index_keys).to include('entity_type' => 1)
      expect(index_keys).to include('event_type' => 1)
      expect(index_keys).to include('occurred_at' => -1)
      expect(index_keys).to include('created_at' => -1)
      expect(index_keys).to include('entity_type' => 1, 'entity_id' => 1)
    end
  end
end
