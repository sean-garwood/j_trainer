Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  resolve("Session") { [ :session ] }
  get "login", to: "sessions#new"
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy"
  get "sign_up", to: "registrations#new"
  post "sign_up", to: "registrations#create"
  resources :passwords, param: :token, ony: %i[create update]

  resources :drills, except: %i[edit update destroy] do
    collection do
      get :train, to: "drills#train" # live training session.
      post :end, to: "drills#end_current" # end current drill
    end

    # Nested route for submitting responses
    resources :drill_clues, only: :create
  end

  resources :clues, only: :show

  root "drills#index"
end
