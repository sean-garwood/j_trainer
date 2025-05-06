class DrillClue < ApplicationRecord
  # TODO: is this really responsibility of the model?
  MAX_RESPONSE_TIME = 15 # seconds
  MAX_BUZZ_IN_TIME  =  5

  belongs_to :drill
  belongs_to :clue

  validates :response_time,
    inclusion: {
      in: 0..MAX_RESPONSE_TIME,
      message: "must be between 0 and #{MAX_RESPONSE_TIME} seconds"
    },
    except_on: :create

  enum :result, { incorrect: -1, pass: 0, correct: 1 }

  before_save :set_result

  private
    def set_result
      if buzzed_in?
        self.result = response_matches_question? ? :correct : :incorrect
      elsif no_buzz? || passed?
        self.result = :pass
      end
    end

    def response_matches_question?
      self.response == clue.question # jeopardy-style
    end

    def buzzed_in?
      true unless no_buzz?
    end

    def no_buzz?
      !response_time || response_time > MAX_BUZZ_IN_TIME
    end

    def passed?
      self.response =~ /\A(?:\s+|p(?:ass))\z/
    end
end
