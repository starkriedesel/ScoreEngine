class ChallengesTeams < ActiveRecord::Migration
  def change
    create_table :challenges_teams, id: false do |t|
      t.references :challenge
      t.references :team
    end
  end
end
