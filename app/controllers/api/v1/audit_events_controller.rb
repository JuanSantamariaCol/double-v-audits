module Api
  module V1
    class AuditEventsController < ApplicationController
      before_action :set_audit_event, only: [:show]

      # GET /api/v1/audit_events
      def index
        @audit_events = AuditEvent.all

        # Apply filters
        @audit_events = @audit_events.where(entity_id: params[:entity_id]) if params[:entity_id].present?
        @audit_events = @audit_events.where(entity_type: params[:entity_type]) if params[:entity_type].present?
        @audit_events = @audit_events.where(event_type: params[:event_type]) if params[:event_type].present?

        # Date range filter
        if params[:start_date].present? && params[:end_date].present?
          start_date = DateTime.parse(params[:start_date])
          end_date = DateTime.parse(params[:end_date])
          @audit_events = @audit_events.by_date_range(start_date, end_date)
        end

        # Order by most recent
        @audit_events = @audit_events.recent

        # Manual pagination
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 25).to_i
        total_count = @audit_events.count
        total_pages = (total_count.to_f / per_page).ceil

        @audit_events = @audit_events.skip((page - 1) * per_page).limit(per_page)

        render json: {
          data: @audit_events.map { |event| AuditEventSerializer.new(event).serializable_hash[:data][:attributes] },
          meta: {
            current_page: page,
            total_pages: total_pages,
            total_count: total_count,
            per_page: per_page
          }
        }, status: :ok
      end

      # GET /api/v1/audit_events/:id
      def show
        render json: {
          data: AuditEventSerializer.new(@audit_event).serializable_hash[:data][:attributes]
        }, status: :ok
      end

      # POST /api/v1/audit_events
      def create
        @audit_event = AuditEvent.new(audit_event_params)

        # Capture IP and User-Agent from request
        @audit_event.ip_address = request.remote_ip
        @audit_event.user_agent = request.user_agent

        if @audit_event.save
          render json: {
            data: AuditEventSerializer.new(@audit_event).serializable_hash[:data][:attributes]
          }, status: :created
        else
          render json: {
            error: 'Validation Error',
            message: 'Failed to create audit event',
            details: @audit_event.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      # GET /api/v1/audit_events/entity/:entity_id
      def by_entity
        @audit_events = AuditEvent.where(entity_id: params[:entity_id]).recent

        # Optional entity_type filter
        @audit_events = @audit_events.where(entity_type: params[:entity_type]) if params[:entity_type].present?

        # Manual pagination
        page = (params[:page] || 1).to_i
        per_page = (params[:per_page] || 25).to_i
        total_count = @audit_events.count
        total_pages = (total_count.to_f / per_page).ceil

        @audit_events = @audit_events.skip((page - 1) * per_page).limit(per_page)

        render json: {
          data: @audit_events.map { |event| AuditEventSerializer.new(event).serializable_hash[:data][:attributes] },
          meta: {
            current_page: page,
            total_pages: total_pages,
            total_count: total_count,
            per_page: per_page
          }
        }, status: :ok
      end

      private

      def set_audit_event
        @audit_event = AuditEvent.find(params[:id])
      end

      def audit_event_params
        params.require(:audit_event).permit(
          :event_type,
          :entity_type,
          :entity_id,
          :action,
          :status,
          :user_agent,
          :ip_address,
          :occurred_at,
          metadata: {}
        )
      end
    end
  end
end
