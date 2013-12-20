class AddPublicToService < ActiveRecord::Migration
  def change
    add_column :services, :public, :boolean, default: true, null: false
  end
end
