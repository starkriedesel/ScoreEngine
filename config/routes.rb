ScoreEngine::Application.routes.draw do
  # Root
  root :to => 'page#home'

  # Users
  devise_for :users

  # Teams
  resources :teams

  # Client Updates
  get '/client_update/poll' => 'clientUpdate#poll'

  # Services
  post '/services/:id/clear' => 'services#clear', as: :clear_service
  post '/logs/:id/clear/:log_id' => 'services#clear', as: :clear_service_log
  get '/services/:id/status/:last_log_id' => 'services#status'
  post '/services/:id/power' => 'services#power', as: :service_power
  get '/services/:team_id/graph' => 'services#graph', as: :services_graph
  resources :services

  # Users
  get '/users' => 'users#index', as: :users
  get '/users/:id/edit' => 'users#edit', as: :edit_user
  put '/users/:id' => 'users#update', as: :user

  # Team Messages
  resources :team_messages, path: 'messages'
  get '/messages/new/:reply_id' => 'teamMessages#new', as: :team_messages_reply
  get '/messages/:id/download' => 'teamMessages#download', as: :team_message_download

  # Server Manager
  get '/serverManager' => 'serverManager#index', as: :server_manager
  get '/serverManager/:id/snapshot' => 'serverManager#snapshot', as: :server_manager_snapshot
  get '/serverManager/:id/rename' => 'serverManager#rename', as: :server_manager_rename
  post '/serverManager/:id/rename' => 'serverManager#rename', as: :server_manager_rename
  post '/serverManager/:id/command/:command' => 'serverManager#command', as: :server_manager_command
  post '/serverManager/:id/revert' => 'serverManager#revert', as: :server_manager_revert
  post '/serverManager/refresh' => 'serverManager#refresh', as: :server_manager_refresh

  # Challenges
  resources :challenges
  resources :challenge_groups, except: [:index, :show]

  # Tools
  get 'tools/hash' => 'tools#hash', as: :hash_tool
  post 'tools/hash' => 'tools#hash_post'
  get 'tools/dns' => 'tools#dns', as: :dns_tool
  post 'tools/dns' => 'tools#dns_post'
  get 'tools/daemon_log' => 'tools#daemon_log', as: :daemon_log
end
