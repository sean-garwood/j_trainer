class RenameClueAnswerAndQuestionFields < ActiveRecord::Migration[8.0]
  def change
    rename_column :clues, :answer, :clue_text
    rename_column :clues, :question, :correct_response
  end
end
