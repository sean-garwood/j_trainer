class AddJudgmentFieldsToDrillClues < ActiveRecord::Migration[8.1]
  def change
    add_column :drill_clues, :score, :float
    add_column :drill_clues, :reason, :string
  end
end
