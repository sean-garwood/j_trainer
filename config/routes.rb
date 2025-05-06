Rails.application.routes.draw do
  resource :session
  resource :registration, only: %i[new create]
  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :passwords, param: :token

  resources :drills, except: %i[edit destroy] do
    collection do
      get :train, to: "drills#train" # live training session.
    end
    member do
      get :stats, to: "drills#show"
    end
  end

  root "drills#index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
end
