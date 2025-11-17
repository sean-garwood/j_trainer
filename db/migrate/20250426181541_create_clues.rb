class CreateClues < ActiveRecord::Migration[8.0]
  def change
    create_table :clues do |t|
      t.integer :round
      t.integer :clue_value
      t.integer :daily_double_value, null: true
      t.text :category
      t.text :comments, null: true
      t.text :answer
      t.text :question
      t.string :air_date
      t.text :notes, null: true

      t.timestamps
    end
  end
end
