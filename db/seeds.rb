# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created
# alongside the database with db:setup).

require 'smarter_csv'

CLUES_FILE_PATH = Rails.root.join('db', 'data', 'combined_season1-39.tsv')

# chunk the data to avoid memory issues
SmarterCSV.process(CLUES_FILE_PATH, { chunk_size: 1000 }) do |chunk|
  chunk.each do |data|
    Clue.create!(data)
  end
end
