class Team < ActiveRecord::Base
  attr_accessible :dns_server, :name

  validates_presence_of :name

  has_many :services
  has_many :users

  def self.options_list
    [['None',nil]] + Team.all.collect{|t| ["#{t.name}", t.id]}
  end
end
