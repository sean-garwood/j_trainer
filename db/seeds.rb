# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end

puts "Seeding clues."

sample_clues = [
  {
    round: 1,
    clue_value: 200,
    category: "HISTORY",
    answer: "This document, signed in 1215, limited the power of the English monarch",
    question: "What is the Magna Carta?",
    air_date: "2022-01-15"
  },
  {
    round: 2,
    clue_value: 400,
    category: "SCIENCE",
    answer: "This element with atomic number 79 has the chemical symbol Au",
    question: "What is Gold?",
    air_date: "2022-01-15"
  }
]

sample_user = User.new(email_address: "foo@bar.com", password: "password")

Clue.insert_all(sample_clues) if Clue.count.zero?
puts "Added #{sample_clues.size} sample clues for #{Rails.env}"
sample_user.save! if User.count.zero?
puts "Added sample user for #{Rails.env}"
puts "Seeding completed."
