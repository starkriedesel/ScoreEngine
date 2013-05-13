FactoryGirl.define do
  factory :user do
    username { "Test#{admin ? 'Admin':'User'}#{(team_id.nil?) ? '0':team_id.to_s}" }
    password { "#{username}_AbC_987" }
    password_confirmation { password }
    admin false
    team_id {(team.nil?) ? nil : team.id}

    factory :admin do
      admin true
    end

    factory :user1 do
      association :team, factory: :team1

      factory :admin1 do
        admin true
      end
    end

    factory :user2 do
      association :team, factory: :team2

      factory :admin2 do
        admin true
      end
    end
  end
end