class CreateDrills < ActiveRecord::Migration[8.0]
  def change
    create_table :drills do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :correct_count
      t.integer :incorrect_count
      t.integer :pass_count
      t.integer :clues_seen_count
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
