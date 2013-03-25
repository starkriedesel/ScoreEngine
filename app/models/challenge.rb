class Challenge < ActiveRecord::Base
  attr_accessible :description, :group_id, :name, :link
  belongs_to :group, class_name: :ChallengeGroup, foreign_key: :group_id
  has_and_belongs_to_many :teams
end
