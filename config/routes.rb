ScoreEngine::Application.routes.draw do
  # Users
  devise_for :users

  # Root
  root :to => 'page#home'

  # Teams
  resources :teams

  # Services
  post '/services/:id/check' => 'services#check', as: :service_check
  post '/services/duplicate' => 'services#duplicate', as: :service_duplicate
  post '/services/:id/clear' => 'services#clear', as: :clear_service
  post '/logs/:id/clear' => 'services#clear_log', as: :clear_service_log
  get '/services/:id/status/:last_log_id' => 'services#status'
  get '/services/status' => 'services#status'
  get '/services/check_all' => 'services#check_all'
  resources :services

  # Users
  get '/users' => 'users#index', as: :users
  get '/users/:id/edit' => 'users#edit', as: :edit_user
  put '/users/:id' => 'users#update', as: :user

  # Team Messages
  resources :team_messages

  # Tools
  get "tools/hash" => 'tools#hash', as: :hash_tool
  post "tools/hash" => 'tools#hash_post'
  get 'tools/dns' => 'tools#dns', as: :dns_tool
  post 'tools/dns' => 'tools#dns_post'
end
