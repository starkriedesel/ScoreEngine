class AddCreatedAtIndexToServiceLog < ActiveRecord::Migration
  def change
    add_index :service_logs, :created_at
  end
end
