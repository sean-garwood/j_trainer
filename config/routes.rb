Rails.application.routes.draw do
  get '/clues', to: 'clues#index'
  resources :clues, only: [:index]
  resources :users, only: %i[new create]
  root to: 'clues#index'
end
