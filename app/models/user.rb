class User < ActiveRecord::Base
  PASS_MIN_LENGTH = 6

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :email, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  validates_presence_of :username, :password
  validates_confirmation_of :password
  validates_length_of :password, minimum: User::PASS_MIN_LENGTH, allow_blank: false
  validates_uniqueness_of :username, case_sensitive: false
  belongs_to :team
end
