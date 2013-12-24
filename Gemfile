source 'https://rubygems.org'

# Rails
gem 'rails', '3.2.14'

# Databases
gem 'sqlite3'
gem 'mysql2', '<= 0.3.11'

# Engines
gem 'thin' # web
gem 'daemons' # daemon

# Assets
gem 'haml-rails' # HAML
gem 'jquery-rails' # JQuery
gem 'jquery-ui-rails'

gem 'therubyracer'

group :assets do
  # CSS
  gem 'sass-rails',   '~> 3.2.3'
  gem 'uglifier', '>= 1.0.3'
  gem 'compass-rails'
  gem 'modular-scale'
  gem 'modernizr-rails'

  # Zurb CSS Framework v5
  gem 'foundation-rails', '~> 5.0.0'

  gem 'font-awesome-rails', '~>4.0.3'
end

# Helper Libs
gem 'devise' # User Authentication
gem 'rails_config' # Config files
gem 'bcrypt-ruby', '~> 3.0.0' # To use ActiveModel has_secure_password

# Development helpers
group :development do
  gem 'better_errors' # better html error messages
  gem 'quiet_assets' # do not display asset retrieval in log file
  gem 'binding_of_caller' # REPL for better_errors
end

# Protocols
gem 'net-dns' # DNS
gem 'net-ssh' # SSH
#gem 'net-ssh-multi' # SSH
gem 'net-sftp' # SFTP
gem 'ftpfxp' # FTP-TLS
gem 'net-ldap' # LDAP / AD

# Server Manager Backends
gem 'aws-sdk', '~>1.0'

# Testing
gem 'rspec-rails', :group => [:development, :test]
gem 'factory_girl_rails', :group => [:development, :test]
group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'launchy'
  gem 'database_cleaner', '<= 1.0.1'
  gem 'forgery'

  # Guard
  gem 'win32console', platforms: [:mswin, :mingw] # terminal colors (windows)
  gem 'wdm', platforms: [:mswin, :mingw], require: false # Windows Directory Monitor
  gem 'guard-rspec'
end