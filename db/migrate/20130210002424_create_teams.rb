class CreateTeams < ActiveRecord::Migration
  def change
    create_table :teams do |t|
      t.string :name
      t.string :dns_server

      t.timestamps
    end
  end
end
