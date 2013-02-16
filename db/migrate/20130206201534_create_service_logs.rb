class CreateServiceLogs < ActiveRecord::Migration
  def change
    create_table :service_logs do |t|
      t.integer :service_id
      t.text :message
      t.text :debug_message
      t.integer :status

      t.timestamps
    end
  end
end
