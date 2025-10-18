class HealthController < ApplicationController
  def index
    render json: {
      status: 'ok',
      service: 'audit-service',
      timestamp: Time.current,
      database: database_status
    }, status: :ok
  end

  private

  def database_status
    Mongoid.default_client.command(ping: 1)
    'connected'
  rescue Mongo::Error
    'disconnected'
  end
end
