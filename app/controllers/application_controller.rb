class ApplicationController < ActionController::API
  rescue_from Mongoid::Errors::DocumentNotFound, with: :not_found
  rescue_from Mongoid::Errors::Validations, with: :validation_error
  rescue_from StandardError, with: :internal_server_error

  private

  def not_found(exception)
    render json: {
      error: 'Not Found',
      message: exception.message
    }, status: :not_found
  end

  def validation_error(exception)
    render json: {
      error: 'Validation Error',
      message: exception.message,
      details: exception.try(:record)&.errors&.full_messages
    }, status: :unprocessable_entity
  end

  def internal_server_error(exception)
    Rails.logger.error("Internal Server Error: #{exception.message}")
    Rails.logger.error(exception.backtrace.join("\n"))

    render json: {
      error: 'Internal Server Error',
      message: 'An unexpected error occurred'
    }, status: :internal_server_error
  end
end
