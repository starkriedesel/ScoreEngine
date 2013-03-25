class AddLinkToChallenge < ActiveRecord::Migration
  def change
    add_column :challenges, :link, :string
  end
end
