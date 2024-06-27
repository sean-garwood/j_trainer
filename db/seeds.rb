require 'smarter_csv'

CLUES_FILE_PATH = Rails.root.join('db', 'data', 'combined_season1-39.tsv')

# Define options for smarter_csv
options = {
  col_sep: "\t", # Specify tab as the column separator
  quote_char: nil, # Disable quote character handling
  chunk_size: 1000, # Process in chunks to avoid memory issues
  remove_empty_values: false, # Keep empty values
  remove_zero_values: false, # Keep zero values
  convert_values_to_numeric: false, # Do not convert values to numeric automatically
  strings_as_keys: true # Use strings as keys for the hash
}

# Process the TSV file in chunks
# Process the TSV file in chunks
SmarterCSV.process(CLUES_FILE_PATH, options) do |chunk|
  chunk.each do |data|
    # Clean and preprocess data if necessary
    data.transform_keys!(&:downcase) # Convert keys to lowercase
    data.transform_keys! { |key| key.gsub(' ', '_') } # Replace spaces with underscores in keys

    # Clean values
    data.each_value do |value|
      next unless value.is_a?(String)

      value.strip! # Remove leading/trailing whitespace
      value.gsub!('\\"', '"') # Replace escaped quotes with actual quotes
      value.gsub!('\\', '') # Remove any remaining backslashes
    end

    # Create Clue records
    Clue.create!(data)
  rescue StandardError => e
    Rails.logger.error "Failed to import data: #{data.inspect}, error: #{e.message}"
  end
end
