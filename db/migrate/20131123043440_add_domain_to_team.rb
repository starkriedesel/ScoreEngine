class AddDomainToTeam < ActiveRecord::Migration
  def change
    add_column :teams, :domain, :string
  end
end
