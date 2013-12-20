class AddFileToTeamMessages < ActiveRecord::Migration
  def change
    add_column :team_messages, :file, :string
  end
end
