class CreateChallenges < ActiveRecord::Migration
  def change
    create_table :challenges do |t|
      t.integer :group_id
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
