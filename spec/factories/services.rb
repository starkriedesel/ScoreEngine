FactoryGirl.define do
  factory :service do
    name 'TestService'
    on false
    params {}
    team_id nil
    worker ''
  end

  factory :http_service do
    name 'HTTP'
    on false
    params({'Http'=>{'rhost'=>'google.com', 'rport'=>'80', 'home_path'=>'/', 'home_check'=>''}})
    team_id nil
    worker 'Http'
  end
end