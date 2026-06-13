class ResponseJudge
  ARTICLES = /\A(the|a|an)\s+/
  SPELLING_RATIO_THRESHOLD = 0.85

  Result = Data.define(:verdict, :score, :reason)

  def self.call(user_response:, correct_response:)
    new(user_response, correct_response).call
  end

  def initialize(user_response, correct_response)
    @user    = strip_articles(normalize(strip_pronouns(user_response.to_s)))
    @correct = strip_articles(normalize(strip_pronouns(correct_response.to_s)))
  end

  def call
    return Result.new(:pass, nil, :blank) if pass?

    if exact?
      Result.new(:correct, 1.0, :exact)
    elsif token_subset?
      Result.new(:correct, 1.0, :token_subset)
    elsif (r = per_token_spelling_ratio) && r >= SPELLING_RATIO_THRESHOLD
      Result.new(:correct, r, :per_token_spelling)
    elsif (r = spelling_ratio) >= SPELLING_RATIO_THRESHOLD
      Result.new(:correct, r, :spelling)
    else
      Result.new(:incorrect, spelling_ratio, :no_match)
    end
  end

  private

  attr_reader :user, :correct

  def pass?
    @user.blank? || @user == "p"
  end

  def exact?
    user == correct
  end

  def token_subset?
    u_tokens = user.split
    c_tokens = correct.split
    return false if u_tokens.empty? || c_tokens.empty?

    min_len = [ 3, c_tokens.map(&:length).min ].min
    u_tokens.all? { |t| t.length >= min_len && c_tokens.include?(t) }
  end

  def per_token_spelling_ratio
    u_tokens = user.split
    c_tokens = correct.split
    return nil if u_tokens.empty? || c_tokens.empty?

    min_len = [ 3, c_tokens.map(&:length).min ].min
    return nil unless u_tokens.all? { |t| t.length >= min_len }

    ratios = u_tokens.map do |ut|
      c_tokens.map { |ct| token_ratio(ut, ct) }.max
    end

    ratios.min
  end

  def token_ratio(a, b)
    distance = Amatch::Levenshtein.new(a).match(b)
    1.0 - (distance.to_f / [ a.length, b.length ].max)
  end

  def spelling_ratio
    @spelling_ratio ||= compute_spelling_ratio
  end

  def compute_spelling_ratio
    return 0.0 if [ user, correct ].any?(&:blank?)

    distance = Amatch::Levenshtein.new(user).match(correct)
    1.0 - (distance.to_f / [ user.length, correct.length ].max)
  end

  def normalize(text)
    text.downcase.gsub(/[^a-z0-9\s]/, "").squeeze(" ").strip
  end

  def strip_articles(text)
    text.sub(ARTICLES, "").strip
  end

  def strip_pronouns(answer)
    answer.downcase
          .gsub(/\A(what|who|where|when|why) (is|are|was|were)\s+/, "")
          .gsub(/\?\z/, "")
          .strip
  end
end
