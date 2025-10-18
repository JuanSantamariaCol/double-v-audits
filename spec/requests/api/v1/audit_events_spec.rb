require 'rails_helper'

RSpec.describe 'Api::V1::AuditEvents', type: :request do
  describe 'GET /api/v1/audit_events' do
    let!(:audit_events) { create_list(:audit_event, 30) }

    context 'without filters' do
      it 'returns paginated audit events' do
        get '/api/v1/audit_events'

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data']).to be_an(Array)
        expect(json['data'].length).to eq(25) # default per_page
        expect(json['meta']).to include('current_page', 'total_pages', 'total_count', 'per_page')
        expect(json['meta']['total_count']).to eq(30)
        expect(json['meta']['total_pages']).to eq(2)
      end

      it 'accepts pagination parameters' do
        get '/api/v1/audit_events', params: { page: 2, per_page: 10 }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data'].length).to eq(10)
        expect(json['meta']['current_page']).to eq(2)
        expect(json['meta']['per_page']).to eq(10)
      end
    end

    context 'with filters' do
      let!(:client_event) { create(:audit_event, entity_type: 'client', entity_id: '123') }
      let!(:invoice_event) { create(:audit_event, :invoice_event, entity_id: '456') }

      it 'filters by entity_id' do
        get '/api/v1/audit_events', params: { entity_id: '123' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data'].map { |e| e['entity_id'] }).to all(eq('123'))
      end

      it 'filters by entity_type' do
        get '/api/v1/audit_events', params: { entity_type: 'invoice' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data'].map { |e| e['entity_type'] }).to all(eq('invoice'))
      end

      it 'filters by event_type' do
        get '/api/v1/audit_events', params: { event_type: 'invoice.created' }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data'].map { |e| e['event_type'] }).to all(eq('invoice.created'))
      end

      it 'filters by date range' do
        old_event = create(:audit_event, occurred_at: 5.days.ago)
        recent_event = create(:audit_event, occurred_at: 1.day.ago)

        get '/api/v1/audit_events', params: {
          start_date: 2.days.ago.iso8601,
          end_date: Time.current.iso8601
        }

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        event_ids = json['data'].map { |e| e['id'] }
        expect(event_ids).to include(recent_event.id.to_s)
        expect(event_ids).not_to include(old_event.id.to_s)
      end
    end

    it 'returns events ordered by most recent' do
      get '/api/v1/audit_events'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      occurred_at_times = json['data'].map { |e| DateTime.parse(e['occurred_at']) }
      expect(occurred_at_times).to eq(occurred_at_times.sort.reverse)
    end
  end

  describe 'GET /api/v1/audit_events/:id' do
    let(:audit_event) { create(:audit_event) }

    context 'when the audit event exists' do
      it 'returns the audit event' do
        get "/api/v1/audit_events/#{audit_event.id}"

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['data']['id']).to eq(audit_event.id.to_s)
        expect(json['data']['event_type']).to eq(audit_event.event_type)
        expect(json['data']['entity_type']).to eq(audit_event.entity_type)
        expect(json['data']['entity_id']).to eq(audit_event.entity_id)
        expect(json['data']['action']).to eq(audit_event.action)
        expect(json['data']['status']).to eq(audit_event.status)
      end
    end

    context 'when the audit event does not exist' do
      it 'returns an error' do
        # Use a valid ObjectId format that doesn't exist
        non_existent_id = BSON::ObjectId.new
        get "/api/v1/audit_events/#{non_existent_id}"

        # Should return an error status (404 or 500)
        expect(response).not_to have_http_status(:ok)
        json = JSON.parse(response.body)

        expect(json['error']).to be_present
        expect(json['message']).to be_present
      end
    end
  end

  describe 'POST /api/v1/audit_events' do
    context 'with valid parameters' do
      let(:valid_params) do
        {
          audit_event: {
            event_type: 'invoice.created',
            entity_type: 'invoice',
            entity_id: '789',
            action: 'create',
            status: 'success',
            metadata: { amount: 500.00, currency: 'USD' }
          }
        }
      end

      it 'creates a new audit event' do
        expect {
          post '/api/v1/audit_events', params: valid_params
        }.to change(AuditEvent, :count).by(1)

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['data']['event_type']).to eq('invoice.created')
        expect(json['data']['entity_type']).to eq('invoice')
        expect(json['data']['entity_id']).to eq('789')
        expect(json['data']['action']).to eq('create')
        expect(json['data']['status']).to eq('success')
        expect(json['data']['metadata']['amount']).to eq('500.0')
        expect(json['data']['metadata']['currency']).to eq('USD')
      end

      it 'captures IP address and User-Agent from request' do
        post '/api/v1/audit_events', params: valid_params,
             headers: { 'User-Agent' => 'Test Agent' }

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['data']['ip_address']).to be_present
        expect(json['data']['user_agent']).to eq('Test Agent')
      end

      it 'sets occurred_at automatically if not provided' do
        post '/api/v1/audit_events', params: valid_params

        expect(response).to have_http_status(:created)
        json = JSON.parse(response.body)

        expect(json['data']['occurred_at']).to be_present
      end
    end

    context 'with invalid parameters' do
      let(:invalid_params) do
        {
          audit_event: {
            event_type: '',
            entity_type: 'invalid_type',
            action: 'invalid_action',
            status: 'invalid_status'
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/audit_events', params: invalid_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['error']).to eq('Validation Error')
        expect(json['details']).to be_an(Array)
        expect(json['details']).not_to be_empty
      end

      it 'does not create an audit event' do
        expect {
          post '/api/v1/audit_events', params: invalid_params
        }.not_to change(AuditEvent, :count)
      end
    end

    context 'with missing required parameters' do
      let(:missing_params) do
        {
          audit_event: {
            event_type: 'test.event'
          }
        }
      end

      it 'returns validation errors' do
        post '/api/v1/audit_events', params: missing_params

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)

        expect(json['error']).to eq('Validation Error')
        expect(json['details']).to include(match(/Entity type/))
        expect(json['details']).to include(match(/Action/))
        expect(json['details']).to include(match(/Status/))
      end
    end
  end

  describe 'GET /api/v1/audit_events/entity/:entity_id' do
    let!(:entity_events) { create_list(:audit_event, 5, entity_id: '999') }
    let!(:other_events) { create_list(:audit_event, 3, entity_id: '888') }

    it 'returns all events for a specific entity' do
      get '/api/v1/audit_events/entity/999'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data'].length).to eq(5)
      expect(json['data'].map { |e| e['entity_id'] }).to all(eq('999'))
    end

    it 'can filter by entity_type' do
      create(:audit_event, entity_id: '999', entity_type: 'invoice')

      get '/api/v1/audit_events/entity/999', params: { entity_type: 'invoice' }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data'].map { |e| e['entity_type'] }).to all(eq('invoice'))
    end

    it 'supports pagination' do
      create_list(:audit_event, 30, entity_id: '777')

      get '/api/v1/audit_events/entity/777', params: { page: 1, per_page: 10 }

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['data'].length).to eq(10)
      expect(json['meta']['current_page']).to eq(1)
      expect(json['meta']['total_count']).to eq(30)
    end

    it 'returns events ordered by most recent' do
      get '/api/v1/audit_events/entity/999'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      occurred_at_times = json['data'].map { |e| DateTime.parse(e['occurred_at']) }
      expect(occurred_at_times).to eq(occurred_at_times.sort.reverse)
    end
  end
end
