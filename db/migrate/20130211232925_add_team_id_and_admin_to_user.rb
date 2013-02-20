class AddTeamIdAndAdminToUser < ActiveRecord::Migration
  def up
    add_column :users, :team_id, :integer
    add_column :users, :admin, :boolean, default: false, null: false

    begin
      remove_index :users, :email
    rescue
    end

    remove_column :users, :email
    add_index :users, :username, :unique => true
  end

  def down
    remove_index :users, :username
    add_column :users, :email, :string, :null => false, :default => ""

    remove_column :users, :team_id
    remove_column :users, :admin
  end
end
