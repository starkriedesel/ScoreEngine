class TeamMessage < ActiveRecord::Base
  attr_accessible :content, :subject, :team_id
end
