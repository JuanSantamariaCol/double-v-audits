require 'rails_helper'

RSpec.describe 'Health Check', type: :request do
  describe 'GET /health' do
    it 'returns a successful health check' do
      get '/health'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['status']).to eq('ok')
      expect(json['service']).to eq('audit-service')
      expect(json['timestamp']).to be_present
      expect(json['database']).to be_in(['connected', 'disconnected'])
    end

    it 'includes database connection status' do
      get '/health'

      expect(response).to have_http_status(:ok)
      json = JSON.parse(response.body)

      expect(json['database']).to be_present
    end
  end
end
