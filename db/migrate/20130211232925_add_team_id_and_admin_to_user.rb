class AddTeamIdAndAdminToUser < ActiveRecord::Migration
  def change
    add_column :users, :team_id, :integer
    add_column :users, :admin, :boolean
  end
end
