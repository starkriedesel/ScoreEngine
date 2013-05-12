FactoryGirl.define do
  factory :user do
    username 'TestUser'
    password 'changeme'
    password_confirmation 'changeme'
    admin false
    team_id nil
  end
end