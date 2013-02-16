class CreateServices < ActiveRecord::Migration
  def change
    create_table :services do |t|
      t.string :name
      t.string :worker
      t.text :params

      t.timestamps
    end
  end
end
