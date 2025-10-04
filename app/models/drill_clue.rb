class DrillClue < ApplicationRecord
  belongs_to :drill
  belongs_to :clue

  validates :response_time,
    inclusion: {
      in: 0..JTrainer::MAX_RESPONSE_TIME,
      message: "must be between 0 and #{JTrainer::MAX_RESPONSE_TIME} seconds"
    },
    except_on: :new

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  before_save :set_result

  def correct?
    result == :correct
  end

  def incorrect?
    result == :incorrect
  end

  def passed?
    result == :pass
  end

  private
    def set_result
      case true
      when response_matches_question?
        self.result = :correct
      when passed?
        self.result = :pass
      else
        self.result = :incorrect
      end
    end

    def response_matches_question?
      Regexp.new(clue.question).match?(response) # jeopardy-style
    end

    def no_buzz?
      !response_time || (response_time > JTrainer::MAX_BUZZ_TIME)
    end

    def passed?
      self.response =~ /\A(?:\s+|p(?:ass))\z/ || no_buzz?
    end
end
