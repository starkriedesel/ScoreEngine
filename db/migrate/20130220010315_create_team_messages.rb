class CreateTeamMessages < ActiveRecord::Migration
  def change
    create_table :team_messages do |t|
      t.integer :team_id
      t.string :subject
      t.text :content
      t.integer :from_admin

      t.timestamps
    end
  end
end
