Rails.application.routes.draw do
  # Root path
  root "players#new"

  # Player routes
  resources :players, only: [ :new, :create ]

  # Game routes
  resources :games, only: [ :index, :show ] do
    member do
      post :join
      post :fire
    end
    resources :shots, only: [ :create ]
  end

  # Board routes
  resources :boards, only: [ :update ]

  # Quick join route
  post "join_game", to: "games#join", as: :join_game

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
