class TeamMessage < ActiveRecord::Base
  #attr_accessible :content, :subject, :team_id, :file
  belongs_to :team

  def self.inbox_outbox options={}, &block
    options[:is_admin] ||= false

    team_messages = TeamMessage
    team_messages = team_messages.where(team_id: options[:team_id]) unless options[:team_id].nil? or options[:is_admin]
    team_messages = team_messages.where('id > ?', options[:last_message_id]) unless options[:last_message_id].nil?
    team_messages = block.call team_messages unless block.nil?
    team_messages = team_messages.order(created_at: :desc).all

    # Sort messages into inbox & outbox
    inbox = []
    outbox = []
    team_messages.each do |m|
      if m.from_admin? ^ options[:is_admin]
        inbox << m
      else
        outbox << m
      end
    end

    {inbox: inbox, outbox: outbox}
  end

  def self.user_new_messages user, last_time_checked
    return 0 if user.is_red_team
    messages = TeamMessage
    messages = messages.where(team_id: user.team_id) unless user.is_admin
    messages = messages.where('created_at > ?', last_time_checked)
    messages = messages.where(from_admin: !(user.is_admin))
    return messages.count
  end
end
