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

user_admin = User.create({username: 'admin', password: 'password', password_confirmation: 'password', admin: true}, without_protection: true)
user_alpha = User.create({username: 'alpha', password: 'password', password_confirmation: 'password', admin: true, team: team_alpha}, without_protection: true)
user_beta = User.create({username: 'beta', password: 'password', password_confirmation: 'password', admin: true, team: team_beta}, without_protection: true)
User.create([{username: 'user1', password: 'password', password_confirmation: 'password', team: team_alpha},
             {username: 'user2', password: 'password', password_confirmation: 'password', team: team_alpha},
             {username: 'user3', password: 'password', password_confirmation: 'password', team: team_beta},
             {username: 'user4', password: 'password', password_confirmation: 'password', team: team_beta}
            ], without_protection: true)

