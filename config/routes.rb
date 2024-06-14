Rails.application.routes.draw do
  get 'session/new'
  get 'session/create'
  get 'session/show'
  get '/clues', to: 'clues#index'
  post 'check_answer', to: 'session#check_answer'
  resources :clues, only: [:index]
  resources :users, only: %i[new create]
  root to: 'clues#index'
end
