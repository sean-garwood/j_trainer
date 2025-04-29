class CreateClues < ActiveRecord::Migration[8.0]
  def change
    create_table :clues do |t|
      t.integer :round
      t.integer :clue_value
      t.integer :daily_double_value, optional: true
      t.text :category
      t.text :comments, optional: true
      t.text :answer
      t.text :question
      t.text :air_date
      t.text :notes, optional: true

      t.timestamps
    end
  end
end
