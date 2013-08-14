source 'https://rubygems.org'

gem 'rails', '~> 3.2.11'

# Bundle edge Rails instead:
# gem 'rails', :git => 'git://github.com/rails/rails.git'

gem 'sqlite3'

# Gems used only for assets and not required
# in production environments by default.
group :assets do
  gem 'sass-rails',   '~> 3.2.3'
  gem 'coffee-rails', '~> 3.2.1'

  # See https://github.com/sstephenson/execjs#readme for more supported runtimes
  # gem 'therubyracer', :platforms => :ruby

  gem 'uglifier', '>= 1.0.3'

  # Foundation CSS Framework
  gem 'compass-rails'
  #gem 'zurb-foundation'
  gem 'modular-scale'
end

# Use HAML
gem 'haml-rails'

gem 'jquery-rails'

# To use ActiveModel has_secure_password
gem 'bcrypt-ruby', '~> 3.0.0'

# Use the Thin webserver
gem 'thin'

# User Authentication / Authorization
gem 'devise'

# For ScoreEngine daemon
gem 'daemons'

# Protocols
gem 'net-dns' # DNS
gem 'net-ssh' # SSH
#gem 'net-ssh-multi' # SSH
gem 'net-sftp' # SFTP
gem 'ftpfxp' # FTP-TLS
gem 'mysql2' # MySQL
gem 'net-ldap' # LDAP / AD

# Testing
gem 'rspec-rails', :group => [:development, :test]
gem 'factory_girl_rails', :group => [:development, :test]
group :test do
  gem 'capybara'
  gem 'poltergeist'
  gem 'launchy'
  gem 'database_cleaner', '<= 1.0.1'
  gem 'forgery'
end

group :development do
  gem 'better_errors' # better html error messages
  gem 'quiet_assets' # do not display asset retrieval in log file
end

# To use Jbuilder templates for JSON
# gem 'jbuilder'

# Deploy with Capistrano
# gem 'capistrano'

# To use debugger
# gem 'debugger'
