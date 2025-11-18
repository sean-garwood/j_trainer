# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Example:
#
#   ["Action", "Comedy", "Drama", "Horror"].each do |genre_name|
#     MovieGenre.find_or_create_by!(name: genre_name)
#   end


user = User.find_or_create_by!(email_address: "foo@bar.com") do |u|
  u.password = "password"
end
puts "Added/found sample user for #{Rails.env}"

# Import clues if none exist.

if Clue.count.zero?
  puts "No clues found. Running clues:import task..."
  begin
    Rake::Task["clues:import"].invoke
    puts "Clue import completed."
  rescue => e
    puts "Error during clue import: #{e.message}"
  end
else
  puts "#{Clue.count} clues already exist. Skipping clues import."
end
