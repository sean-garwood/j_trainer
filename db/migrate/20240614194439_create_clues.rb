class CreateClues < ActiveRecord::Migration[7.1]
  def change
    create_table :clues do |t|
      t.integer :round
      t.integer :clue_value
      t.integer :daily_double_value
      t.text :category
      t.text :comments
      t.text :answer
      t.text :question
      t.text :air_date
      t.text :notes

      t.timestamps
    end
  end
end
