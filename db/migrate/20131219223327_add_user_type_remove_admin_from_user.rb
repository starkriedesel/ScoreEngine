class AddUserTypeRemoveAdminFromUser < ActiveRecord::Migration
  def up
    add_column :users, :user_type, :integer, default: 0, null: false
    remove_column :users, :admin
  end

  def down
    add_column :users, :admin, :boolean, default: false, null: false
  end
end
