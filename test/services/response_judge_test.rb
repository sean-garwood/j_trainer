require "test_helper"

class ResponseJudgeTest < ActiveSupport::TestCase
  # --- Pass detection ---

  test "blank response is a pass" do
    result = ResponseJudge.call(user_response: "", correct_response: "What is the Jordan?")
    assert_equal :pass, result.verdict
    assert_nil result.score
    assert_equal :blank, result.reason
  end

  test "nil response is a pass" do
    result = ResponseJudge.call(user_response: nil, correct_response: "What is the Jordan?")
    assert_equal :pass, result.verdict
  end

  test "'p' response is a pass" do
    result = ResponseJudge.call(user_response: "p", correct_response: "What is the Jordan?")
    assert_equal :pass, result.verdict
    assert_equal :blank, result.reason
  end

  test "'P' uppercase is a pass" do
    result = ResponseJudge.call(user_response: "P", correct_response: "What is the Jordan?")
    assert_equal :pass, result.verdict
  end

  test "'pass' is NOT a pass — treated as normal response" do
    result = ResponseJudge.call(user_response: "pass", correct_response: "What is the Jordan?")
    assert_not_equal :pass, result.verdict
  end

  test "'pass' matches an answer containing 'pass'" do
    result = ResponseJudge.call(user_response: "Donner Pass", correct_response: "What is the Donner Pass?")
    assert_equal :correct, result.verdict
  end

  # --- Exact match ---

  test "exact match after normalization" do
    result = ResponseJudge.call(user_response: "the jordan", correct_response: "What is the Jordan?")
    assert_equal :correct, result.verdict
    assert_equal 1.0, result.score
    assert_equal :exact, result.reason
  end

  test "exact match is case insensitive" do
    result = ResponseJudge.call(user_response: "ABRAHAM LINCOLN", correct_response: "Who is Abraham Lincoln?")
    assert_equal :correct, result.verdict
    assert_equal :exact, result.reason
  end

  test "exact match ignores punctuation" do
    result = ResponseJudge.call(user_response: "c++", correct_response: "What is C++?")
    assert_equal :correct, result.verdict
  end

  # --- Pronoun stripping ---

  test "strips 'What is' prefix from correct response" do
    result = ResponseJudge.call(user_response: "jordan", correct_response: "What is the Jordan?")
    assert_equal :correct, result.verdict
  end

  test "strips 'Who is' prefix from correct response" do
    result = ResponseJudge.call(user_response: "Abraham Lincoln", correct_response: "Who is Abraham Lincoln?")
    assert_equal :correct, result.verdict
  end

  test "strips 'Where is' prefix" do
    result = ResponseJudge.call(user_response: "paris", correct_response: "Where is Paris?")
    assert_equal :correct, result.verdict
  end

  test "strips 'What are' prefix" do
    result = ResponseJudge.call(user_response: "the andes", correct_response: "What are the Andes?")
    assert_equal :correct, result.verdict
  end

  test "strips 'Who was' prefix" do
    result = ResponseJudge.call(user_response: "cleopatra", correct_response: "Who was Cleopatra?")
    assert_equal :correct, result.verdict
  end

  # --- Article stripping ---

  test "strips leading article 'the' from correct response" do
    result = ResponseJudge.call(user_response: "jordan", correct_response: "What is the Jordan?")
    assert_equal :correct, result.verdict
  end

  test "user can include 'the' and still match" do
    result = ResponseJudge.call(user_response: "the jordan", correct_response: "What is the Jordan?")
    assert_equal :correct, result.verdict
  end

  # --- Token subset matching ---

  test "last name matches full name" do
    result = ResponseJudge.call(user_response: "lincoln", correct_response: "Who is Abraham Lincoln?")
    assert_equal :correct, result.verdict
    assert_equal 1.0, result.score
    assert_equal :token_subset, result.reason
  end

  test "single short token rejected by proportional guard" do
    result = ResponseJudge.call(user_response: "a", correct_response: "Who is Abraham Lincoln?")
    assert_equal :incorrect, result.verdict
  end

  test "token 'ham' does not match 'Abraham Lincoln'" do
    result = ResponseJudge.call(user_response: "ham", correct_response: "Who is Abraham Lincoln?")
    assert_equal :incorrect, result.verdict
  end

  test "single char matches when correct answer is also single char" do
    result = ResponseJudge.call(user_response: "c", correct_response: "What is C++?")
    assert_equal :correct, result.verdict
  end

  # --- Spelling tolerance (Levenshtein) ---

  test "minor misspelling accepted" do
    result = ResponseJudge.call(user_response: "Abrham Lincoln", correct_response: "Who is Abraham Lincoln?")
    assert_equal :correct, result.verdict
    assert_equal :spelling, result.reason
    assert result.score >= 0.85
  end

  test "completely wrong answer rejected" do
    result = ResponseJudge.call(user_response: "Thomas Jefferson", correct_response: "Who is Abraham Lincoln?")
    assert_equal :incorrect, result.verdict
    assert_equal :no_match, result.reason
  end

  # --- Incorrect answers ---

  test "wrong answer is incorrect" do
    result = ResponseJudge.call(user_response: "Wrong answer", correct_response: "What is the Jordan?")
    assert_equal :incorrect, result.verdict
  end

  test "score is returned for incorrect answers" do
    result = ResponseJudge.call(user_response: "Wrong answer", correct_response: "What is the Jordan?")
    assert_not_nil result.score
    assert result.score < 0.85
  end

  # --- Result structure ---

  test "result has verdict, score, and reason" do
    result = ResponseJudge.call(user_response: "jordan", correct_response: "What is the Jordan?")
    assert_respond_to result, :verdict
    assert_respond_to result, :score
    assert_respond_to result, :reason
  end
end
