Rails.application.routes.draw do
  # Health check endpoint
  get "health", to: "health#index"

  # API routes
  namespace :api do
    namespace :v1 do
      resources :audit_events, only: [:index, :show, :create] do
        collection do
          get 'entity/:entity_id', to: 'audit_events#by_entity', as: :by_entity
        end
      end
    end
  end
end
