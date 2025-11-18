namespace :clues do
  # TODO: only grab clues with specific category names that match the subjects
  # that we want to track stats for.
  # e.g. "History", but not "European History"
  # This ensures that we are properly tagging clues for user stats.
  # Of course, the release will be more comprehensive later on.
  desc "Import clues from TSV file (db/data/combined_season1-40.tsv)"
  task import: :environment do
    require "csv"

    file_path = Rails.root.join("db/data/combined_season1-40.tsv")

    unless File.exist?(file_path)
      puts "Error: File not found at #{file_path}"
      puts "Please ensure the TSV file is placed at this location."
      exit 1
    end

    puts "Starting import from #{file_path}..."
    puts "This may take several minutes for large files.\n"

    imported_count = 0
    skipped_count = 0
    error_count = 0
    batch_size = 1000
    batch = []

    # Read the file and clean up the escaping issues
    File.open(file_path, "r:UTF-8") do |file|
      # Read header line
      header_line = file.gets
      unless header_line
        puts "Error: File is empty"
        exit 1
      end

      # Clean and parse header
      header = header_line.strip.split("\t").map(&:strip)
      puts "Columns found: #{header.join(', ')}\n"

      # Expected columns from the TSV
      # round, clue_value, daily_double_value, category, comments, answer, question, air_date, notes
      required_indices = {
        round: header.index("round") || 0,
        clue_value: header.index("clue_value") || 1,
        daily_double_value: header.index("daily_double_value") || 2,
        category: header.index("category") || 3,
        comments: header.index("comments") || 4,
        answer: header.index("answer") || 5,  # Maps to clue_text
        question: header.index("question") || 6,  # Maps to correct_response
        air_date: header.index("air_date") || 7,
        notes: header.index("notes") || 8
      }

      line_number = 1

      file.each_line do |line|
        line_number += 1

        begin
          # Clean the line: unescape the backslash-escaped quotes
          cleaned_line = line.gsub('\"', '"').gsub("\\'", "'")

          # Split by tabs
          fields = cleaned_line.split("\t", -1)

          # Extract and clean fields
          round = fields[required_indices[:round]]&.strip
          clue_value = fields[required_indices[:clue_value]]&.strip
          daily_double_value = fields[required_indices[:daily_double_value]]&.strip
          category = fields[required_indices[:category]]&.strip
          comments = fields[required_indices[:comments]]&.strip
          clue_text = fields[required_indices[:answer]]&.strip  # "answer" in TSV = clue_text in DB
          correct_response = fields[required_indices[:question]]&.strip  # "question" in TSV = correct_response in DB
          air_date = fields[required_indices[:air_date]]&.strip
          notes = fields[required_indices[:notes]]&.strip

          # Skip if missing required fields
          if round.blank? || clue_value.blank? || category.blank? || clue_text.blank? || correct_response.blank? || air_date.blank?
            skipped_count += 1
            next
          end

          # Parse round (handle string values like "Jeopardy!" -> 1, "Double Jeopardy!" -> 2, "Final Jeopardy!" -> 3)
          # round_num = case round.downcase
          # when /final/
          #   3
          # when /double/
          #   2
          # else
          #   round.to_i.zero? ? 1 : round.to_i
          # end

          # Parse clue value - remove $ and commas
          # clue_value_num = clue_value.gsub(/[\$,]/, "").to_i

          # Handle zero or invalid clue values - use defaults based on round
          # if clue_value_num.zero?
          #   clue_value_num = case round_num
          #   when 1
          #     200  # Default for Jeopardy round
          #   when 2
          #     400  # Default for Double Jeopardy
          #   when 3
          #     0    # Final Jeopardy has no fixed value
          #   end
          # end

          # Parse air date
          parsed_air_date = begin
            Date.parse(air_date)
          rescue
            Date.today  # Fallback if date parsing fails
          end

          batch << {
            round: round.to_i,
            clue_value: clue_value.to_i,
            daily_double_value: daily_double_value.to_i,
            category: category,
            comments: comments,
            clue_text: clue_text,
            correct_response: correct_response,
            air_date: parsed_air_date,
            notes: notes,
            created_at: Time.current,
            updated_at: Time.current
          }

          # Insert batch when it reaches batch_size
          if batch.size >= batch_size
            Clue.insert_all(batch)
            imported_count += batch.size
            batch.clear
            print "\rImported: #{imported_count} | Skipped: #{skipped_count} | Errors: #{error_count}"
          end

        rescue => e
          error_count += 1
          if error_count <= 10  # Only show first 10 errors
            puts "\nError on line #{line_number}: #{e.message}"
            puts "Line content: #{line[0..100]}..." if line
          end
        end
      end

      # Insert remaining batch
      if batch.any?
        Clue.insert_all(batch)
        imported_count += batch.size
      end
    end

    puts "\n\n" + "=" * 50
    puts "Import completed!"
    puts "=" * 50
    puts "Successfully imported: #{imported_count} clues"
    puts "Skipped (missing data): #{skipped_count} rows"
    puts "Errors encountered: #{error_count} rows"
    puts "Total clues in database: #{Clue.count}"
    puts "=" * 50
  end

  desc "Clear all clues from the database"
  task clear: :environment do
    print "Are you sure you want to delete all #{Clue.count} clues? (yes/no): "
    confirmation = STDIN.gets.chomp
    if confirmation.downcase == "yes"
      count = Clue.count
      Clue.delete_all
      puts "Deleted #{count} clues."
    else
      puts "Cancelled."
    end
  end

  desc "Show import statistics"
  task stats: :environment do
    total = Clue.count
    puts "=" * 50
    puts "Clue Statistics"
    puts "=" * 50
    puts "Total clues: #{total}"
    puts "\nBy Round:"
    Clue.group(:round).count.sort.each do |round, count|
      round_name = case round
      when 1
        "Jeopardy!"
      when 2
        "Double Jeopardy!"
      when 3
        "Final Jeopardy!"
      else
        "Unknown"
      end
      puts "  #{round_name}: #{count} (#{(count.to_f / total * 100).round(1)}%)"
    end
    puts "\nBy Clue Value:"
    Clue.group(:clue_value).order(:clue_value).count.each do |value, count|
      puts "  $#{value}: #{count}"
    end
    puts "\nDate Range:"
    puts "  Earliest: #{Clue.minimum(:air_date)}"
    puts "  Latest: #{Clue.maximum(:air_date)}"
    puts "\nTop 10 Categories:"
    Clue.group(:category).count.sort_by { |_, count| -count }.first(10).each do |category, count|
      puts "  #{category}: #{count}"
    end
    puts "=" * 50
  end
end
