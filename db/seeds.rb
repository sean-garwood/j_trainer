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

user = User.find_or_create_by!(email_address: "foo@bar.com") do |u|
  u.password = "password"
end
puts "Added/found sample user for #{Rails.env}"

Clue.insert_all(sample_clues) if Clue.count.zero?
puts "Added #{sample_clues.size} sample clues for #{Rails.env}"

drill = Drill.find_or_create_by!(user: user) do |d|
  d.started_at = Time.now
  d.ended_at = Time.now + 5.minutes
  d.correct_count = 0
  d.incorrect_count = 0
  d.pass_count = 0
end
puts "Added sample drill for #{Rails.env}"

DrillClue.find_or_create_by!(drill: drill, clue: Clue.first) do |dc|
  dc.response_time = 1.5
  dc.response = "What is the Magna Carta?"
end
puts "Added sample drill clue for #{Rails.env}"

puts "Seeding completed."
