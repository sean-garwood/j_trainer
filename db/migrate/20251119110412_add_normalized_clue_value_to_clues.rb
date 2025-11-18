class AddNormalizedClueValueToClues < ActiveRecord::Migration[8.0]
  def change
    add_column :clues, :normalized_clue_value, :integer, default: 0
  end
end
