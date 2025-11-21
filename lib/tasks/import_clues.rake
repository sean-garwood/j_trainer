namespace :clues do
  # TODO: tags/categories filtering
  # that we want to track stats for.
  # e.g. "History", but not "European History"
  # This ensures that we are properly tagging clues for user stats.
  # Of course, the release will be more comprehensive later on.
  desc "Import clues from TSV file (db/data/combined_season1-40.tsv)"
  task import: :environment do
    require "csv"
    include ClueValueHelper
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

    File.open(file_path, "r:UTF-8") do |file|
      required_indices = get_col_indices(file)
      line_number = 1

      file.each_line do |line|
        line_number += 1

        begin
          # Unescape the backslash-escaped quotes
          cleaned_line = line.gsub('\"', '"').gsub("\\'", "'")
          fields = cleaned_line.split("\t", -1)

          # Extract and clean fields
          round = fields[required_indices[:round]]&.strip
          clue_value = fields[required_indices[:clue_value]]&.strip
          daily_double_value = fields[required_indices[:daily_double_value]]&.strip
          category = fields[required_indices[:category]]&.strip
          comments = fields[required_indices[:comments]]&.strip
          # "answer" in TSV = clue_text in DB
          clue_text = fields[required_indices[:answer]]&.strip
          # "question" in TSV = correct_response in DB
          correct_response = fields[required_indices[:question]]&.strip
          air_date = fields[required_indices[:air_date]]&.strip
          notes = fields[required_indices[:notes]]&.strip

          # Skip if missing required fields
          if round.blank? || clue_value.blank? || category.blank? ||
            clue_text.blank? || correct_response.blank? || air_date.blank?
            skipped_count += 1
            next
          end

          parsed_air_date = begin
            Date.parse(air_date)
          rescue StandardError
            Date.today  # Fallback if date parsing fails
          end

          batch << {
            round: round.to_i,
            clue_value: clue_value.to_i,
            normalized_clue_value:
              ClueValueHelper.normalize_clue_value(clue_value.to_i, air_date),
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

          if batch.size >= batch_size
            Clue.insert_all(batch)
            imported_count += batch.size
            batch.clear
            print "\rImported: #{imported_count} | Skipped: #{skipped_count} | Errors: #{error_count}"
          end

        rescue StandardError => e
          error_count += 1
          if error_count <= 10  # Only show first 10 errors
            puts "\nError on line #{line_number}: #{e.message}"
            puts "Line content: #{line[0..100]}..." if line
          end
        end
      end

      if batch.any?
        Clue.insert_all(batch)
        imported_count += batch.size
      end
    end

    puts "\n\n#{line_break}"
    puts "Import completed!"
    line_break
    puts "Successfully imported: #{imported_count} clues"
    puts "Skipped (missing data): #{skipped_count} rows"
    puts "Errors encountered: #{error_count} rows"
    puts "Total clues in database: #{Clue.count}"
    line_break
  end

  desc "Clear all clues from the database"
  task clear: :environment do
    print "Are you sure you want to delete all #{Clue.count} clues? (yes/no): "
    confirmation = $stdin.gets.chomp
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
    aggregate_clues_by = lambda do |col, should_order = false|
        if should_order
          Clue.group(col).order(col).count
        else
          Clue.group(col).count
        end
      end
    print_header
    show_total_clues_info
    puts "\nBy Round:"
    aggregate_clues_by.call(:round).sort.each do |round, count|
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
    aggregate_clues_by.call(:clue_value, true).each do |value, count|
      puts "  $#{value}: #{count}"
    end
    puts "\nBy Normalized Clue Value:"
    aggregate_clues_by.call(:normalized_clue_value, true).each do |value, count|
      puts "  $#{value}: #{count}"
    end
    show_date_range
    top_categories_to_show = 100
    puts "\nTop #{top_categories_to_show} Categories:"
    aggregate_clues_by.call(:category).sort_by { |_, count| -count }
      .first(top_categories_to_show).each do |category, count|
        puts "  #{category}: #{count}"
    end
    line_break
  end

  private
    def get_col_indices(file)
        header_line = file.gets
        unless header_line
          puts "Error: File is empty"
          exit 1
        end

        header = header_line.strip.split("\t").map(&:strip)
        puts "Columns found: #{header.join(', ')}\n"

        {
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
    end

    def line_break(width = 80)
      ("=" * width).to_s
    end

    def show_date_range
      date_range = <<~DATE_RANGE
      Date Range:
        Earliest: #{Clue.minimum(:air_date)}
        Latest: #{Clue.maximum(:air_date)}
      DATE_RANGE
      puts date_range
    end

    def show_total_clues_info(total = Clue.count)
      total_clues_info = <<~TOTAL_CLUES_INFO
      Total clues: #{total}
      #{line_break}
      TOTAL_CLUES_INFO
      puts total_clues_info
    end

    def print_header
      header = <<~HEADER
      #{line_break}
      Clue Statistics
      HEADER
      puts header
    end
end
