class CreateDrillClues < ActiveRecord::Migration[8.0]
  def change
    create_table :drill_clues do |t|
      t.references :drill, null: false, foreign_key: true
      t.references :clue, null: false, foreign_key: true
      t.integer :result
      t.float :response_time
      t.string :response

      t.timestamps
    end

    add_index :drill_clues, [ :drill_id, :clue_id ], unique: true
  end
end
