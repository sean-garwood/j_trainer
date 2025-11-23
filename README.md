# J! Trainer

Hone your Jeopardy! skills using real clues from the game. Inspired by
[Protobowl](https://protobowl.com/jeopardy/lobby) and [J! Scorer](https://j-scorer.com).

## Features

* Participate in "drills", which serve real Jeopardy! clues from seasons 1-40.
  * Judges (very strictly) the correctness of a response
  * Persists results to a database
  * Presents a view in which users can look at past results in tabular form and
     drill down to see past responses.
* View any clue in the game
* Allow user to filter clues

## Roadmap

1. Improve matching logic
   * only exactish^ matches on clues; misspellings are marked incorrect.
   > *\^ \- strips who/what... is , downcases*
   * should handle misspellings without being *too* graceful; protobowl had a
     cheat where one could type the first few letters of an answer and it'd be
     correct.

   * Thinking that we might want to check:
      * len of response close to ans?
      * bidirectionally check regex matches on len(response) / 2 - 1 ends of response
1. Stats view
   * Table view by category/right/wrong/pass
   * Overall lifetime score
   * Score by category
   * Heat map
      * Identify maximal opportunity where:
         * Frequency of category is high
         * Efficiency (dollars gained/dollars possible) is low
1. Rich stats: filter results by
   * Categories
   * Dollar amount
   * Round
   * See population results
1. Implement buzzer
   * Time responses, submit when time is up
   * Jeopardy-style bar to count down buzz-in time
