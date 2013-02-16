class AddOnToService < ActiveRecord::Migration
  def change
    add_column :services, :on, :boolean
  end
end
