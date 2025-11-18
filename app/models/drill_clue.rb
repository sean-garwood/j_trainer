class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  validates :response_time,
    inclusion: {
      in: 0..JTrainer::MAX_RESPONSE_TIME,
      message: "must be between 0 and #{JTrainer::MAX_RESPONSE_TIME} seconds"
    },
    unless: :new_record?

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  before_save :set_result
  after_commit :update_drill_counts


  private
    def set_result
      case true
      when response_matches_correct_response?
        self.result = :correct
      when response_indicates_pass?
        self.result = :pass
      else
        self.result = :incorrect
      end
    end

    # TODO: improve matching logic
    def response_matches_correct_response?
      return false if response.blank?

      # Extract answer from "What is X?" format if present
      # TODO: accept last name only for person answers (except Jones, etc.)
      answer_text = strip_pronouns(clue.correct_response)

      # Normalize both strings: downcase, remove punctuation, trim
      normalized_response = normalize_text(response)
      normalized_answer = normalize_text(answer_text)

      # Check if response contains the key answer terms (bidirectional)
      normalized_answer.include?(normalized_response) ||
        normalized_response.include?(normalized_answer)
    end

    def response_indicates_pass?
      response.blank? ||
      normalize_text(response).match?(/\Ap(?:ass)?\z/i) ||
      no_buzz?
    end

    def no_buzz?
      response_time.to_f > JTrainer::MAX_BUZZ_TIME
    end

    def update_drill_counts
      drill.update_counts!
    end

    # TODO: move to module
    def normalize_text(text)
      text.downcase.gsub(/[^a-z0-9\s]/, "").strip
    end

    def strip_pronouns(answer)
      answer.downcase.gsub(/\A(what|who|where|when|why) is\s+/, "").gsub(/\??\z/, "").strip
    end
end
