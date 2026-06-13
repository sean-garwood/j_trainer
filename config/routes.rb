Rails.application.routes.draw do
  get    "sign_in", to: "sessions#new",     as: :sign_in
  post   "sign_in", to: "sessions#create"
  delete "sign_in", to: "sessions#destroy"
  get    "sign_up", to: "registrations#new"
  post   "sign_up", to: "registrations#create"
  resources :passwords, param: :token, only: %i[new create edit update]

  resources :drills, except: %i[edit update destroy] do
    collection do
      get :train # Show filter configuration page
      get :start, to: redirect("/drills/train") # Handle browser refresh after POST
      post :start # Create drill with filters and begin training
      post :end, to: "drills#end_current", as: "end" # end current drill
    end

    # Nested route for submitting responses
    resources :drill_clues, only: :create
  end

  resources :clues, only: :show

  root "drills#index"
end
