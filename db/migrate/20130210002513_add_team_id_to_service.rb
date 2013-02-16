class AddTeamIdToService < ActiveRecord::Migration
  def change
    add_column :services, :team_id, :integer
  end
end
