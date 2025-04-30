class CreateDrills < ActiveRecord::Migration[8.0]
  def change
    create_table :drills do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :correct_count, default: 0
      t.integer :incorrect_count, default: 0
      t.integer :pass_count, default: 0
      t.integer :clues_seen_count, default: 0
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end
