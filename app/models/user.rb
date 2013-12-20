class User < ActiveRecord::Base
  PASS_MIN_LENGTH = 6

  USER = 0
  ADMIN = 1
  RED_TEAM = 2

  # Include default devise modules. Others available are:
  # :token_authenticatable, :confirmable,
  # :lockable, :timeoutable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable, :trackable

  # Setup accessible (or protected) attributes for your model
  attr_accessible :username, :password, :password_confirmation, :remember_me
  # attr_accessible :title, :body

  validates_presence_of :username
  validates_confirmation_of :password
  validates_uniqueness_of :username, case_sensitive: false

  validates_length_of :password, minimum: PASS_MIN_LENGTH, allow_blank: true
  validates_presence_of :password, if: :password_required?

  belongs_to :team

  # Borrowed from device validatable
  def password_required?
    !persisted? || !password.nil? || !password_confirmation.nil?
  end

  def is_admin
    user_type == ADMIN
  end

  def is_red_team
    user_type == RED_TEAM
  end

  def is_user
    user_type == USER
  end
end
