# -*- mode: ruby -*-
# vi: set ft=ruby :

$mysql_pass = 'password'
$script = <<SCRIPT
echo "mysql-server-5.5 mysql-server/root_password password #{$mysql_pass}" | debconf-set-selections
echo "mysql-server-5.5 mysql-server/root_password_again password #{$mysql_pass}" | debconf-set-selections
apt-get update && apt-get install -y ruby libmysqlclient-dev git subversion mysql-client libvirt-dev mysql-server vim curl ruby-dev build-essential libsqlite3-dev
gem install bundler
cd /vagrant
bundle install
echo "CREATE DATABASE IF NOT EXISTS ScoreEngine; GRANT ALL ON ScoreEngine.* TO 'ScoreEngine'@'localhost' IDENTIFIED BY 'ScoreEngine' WITH GRANT OPTION; FLUSH PRIVILEGES;" | mysql -u root -p#{$mysql_pass}
mkdir /vagrant/tmp && mkdir /vagrant/tmp/uploads && chmod 777 /vagrant/tmp/uploads
SCRIPT

Vagrant.configure(2) do |config|
  config.vm.box = 'ubuntu/trusty64'

  config.vm.provision 'shell', inline: $script

  config.vm.network 'forwarded_port', guest: 3000, host:3001
end
