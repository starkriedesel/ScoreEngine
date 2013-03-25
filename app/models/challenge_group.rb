class ChallengeGroup < ActiveRecord::Base
  attr_accessible :name
  has_many :challenges, foreign_key: :group_id

  def self.options_list
    ChallengeGroup.all.collect{|t| ["#{t.name}", t.id]}
  end
end
