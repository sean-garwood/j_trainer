class CreateSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :sessions do |t|
      t.integer :correct
      t.integer :incorrect
      t.integer :pass
      t.integer :winnings

      t.timestamps
    end
  end
end
