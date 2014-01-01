# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Team.destroy_all
User.destroy_all
TeamMessage.destroy_all
Service.destroy_all
ServiceLog.destroy_all
ChallengeGroup.destroy_all
Challenge.destroy_all

team_alpha = Team.create(name: 'Alpha', dns_server: '')
team_beta = Team.create(name: 'Beta', dns_server: '')

user_admin = User.create({username: 'admin', password: 'password', password_confirmation: 'password', user_type: User::ADMIN}, without_protection: true)
user_red = User.create({username: 'red', password: 'password', password_confirmation: 'password', user_type: User::RED_TEAM}, without_protection: true)
user_red_alpha = User.create({username: 'redAlpha', password: 'password', password_confirmation: 'password', user_type: User::RED_TEAM, team: team_alpha}, without_protection: true)
user_red_beta = User.create({username: 'redBeta', password: 'password', password_confirmation: 'password', user_type: User::RED_TEAM, team: team_beta}, without_protection: true)
User.create([{username: 'user1', password: 'password', password_confirmation: 'password', user_type: User::USER, team: team_alpha},
             {username: 'user2', password: 'password', password_confirmation: 'password', user_type: User::USER, team: team_alpha},
             {username: 'user3', password: 'password', password_confirmation: 'password', user_type: User::USER, team: team_beta},
             {username: 'user4', password: 'password', password_confirmation: 'password', user_type: User::USER, team: team_beta}
            ], without_protection: true)

alpha_http_service = Service.create({name: 'Google', on: false, team: team_alpha, worker: 'Http', params: {
    'Http'=>{'rhost'=>'google.com', 'rport'=>'80', 'home_path'=>'/', 'home_check'=>''}
}}, without_protection: true)
beta_http_service = alpha_http_service.dup
beta_http_service.team_id = team_beta.id
beta_http_service.save

alpha_dns_service = Service.create({name: 'Google DNS', on: false, team: team_alpha, worker: 'Dns', params: {
    'Dns'=>{'rhost'=>'8.8.8.8', 'rport'=>'53', 'hostname'=>'yahoo.com', 'record_type'=>'A'}
}}, without_protection: true)
beta_dns_service = alpha_dns_service.dup
beta_dns_service.team_id = team_beta.id
beta_dns_service.save

