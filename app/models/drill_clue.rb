class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue
  # https://edgeapi.rubyonrails.org/classes/ActiveRecord/DelegatedType.html
  delegate :correct_response, to: :clue

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  before_save :set_result
  after_commit :update_drill_counts


  private
    def set_result
      self.result = if response_matches_correct_response?
        :correct
      elsif response_indicates_pass?
        :pass
      else
        :incorrect
      end
    end

    # TODO: improve matching logic
    #   accept last name only for person answers (except Jones, etc.)
    def response_matches_correct_response?
      exact_match?(correct_response)
    end

    def exact_match?(correct_response)
      return false if response.blank?

      # Extract answer from "What is X?" format if present
      answer_text = strip_pronouns(correct_response)

      # Normalize both strings: downcase, remove punctuation, trim
      normalized_response = normalize_text(response)
      normalized_answer = normalize_text(answer_text)

      # Check if response contains the key answer terms (bidirectional)
      normalized_answer.include?(normalized_response) ||
        normalized_response.include?(normalized_answer)
    end

    def response_indicates_pass?
      response.blank? ||
      normalize_text(response).match?(/\Ap(?:ass)?\z/i)
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
