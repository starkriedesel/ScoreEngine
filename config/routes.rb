ScoreEngine::Application.routes.draw do
  # Root
  root :to => 'page#home'

  # Users
  devise_for :users

  # Teams
  resources :teams
  get '/teams/:id/graph' => 'teams#graph', as: :team_graph

  # Client Updates
  get '/client_update/poll' => 'client_update#poll'

  # Services
  post '/services/:id/clear' => 'services#clear', as: :clear_service
  post '/logs/:id/clear/:log_id' => 'services#clear', as: :clear_service_log
  get '/services/:id/status/:last_log_id' => 'services#status'
  post '/services/:id/power' => 'services#power', as: :service_power
  get '/services/:id/graph/:type' => 'services#graph', as: :services_graph
  resources :services

  # Scoreboard
  get '/scoreboard' => 'scoreboard#index', as: :scoreboard
  get '/scoreboard/graph/:graph_model/:id/:graph_name' => 'scoreboard#graph'

  # Users
  get '/users' => 'users#index', as: :users
  get '/users/:id/edit' => 'users#edit', as: :edit_user
  patch '/users/:id' => 'users#update', as: :user

  # Team Messages
  resources :team_messages, path: 'messages'
  get '/messages/new/:reply_id' => 'team_messages#new', as: :team_messages_reply
  get '/messages/:id/download' => 'team_messages#download', as: :team_message_download

  # Server Manager
  get '/serverManager' => 'server_manager#index', as: :server_manager
  post '/serverManager/refresh' => 'server_manager#refresh', as: :server_manager_refresh
  post '/serverManager/start_libvirt' => 'server_manager#start_libvirt', as: :server_manager_start_libvirt
  get '/serverManager/:id/:command' => 'server_manager#command', as: :server_manager_command
  post '/serverManager/:id/:command' => 'server_manager#command'

  # Tools
  get 'tools/hash' => 'tools#hash', as: :hash_tool
  post 'tools/hash' => 'tools#hash_post'
  get 'tools/dns' => 'tools#dns', as: :dns_tool
  post 'tools/dns' => 'tools#dns_post'
  get 'tools/daemon_log' => 'tools#daemon_log', as: :daemon_log
end
