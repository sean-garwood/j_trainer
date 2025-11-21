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

## Roadmap

1. Allow user to filter clues by some criteria, e.g.
   * Air date
   * Category
      * Might be overly restrictive; ideally we would filter by subject, but it
        is not implemented. For instance, would be nice to just grab "history"
        clues, which might have categories like "U.S History", "European
        History", "Historical Figures", etc.
1. Rich stats: filter results by
   * Categories
   * Dollar amount
   * Round
   * See population results
1. Stats view
   * Table view by category/right/wrong/pass
   * Overall lifetime score
   * Score by category
   * Heat map
      * Identify maximal opportunity where:
         * Frequency of category is high
         * Efficiency (dollars gained/dollars possible) is low
1. Implement buzzer
   * Time responses, submit when time is up
   * Jeopardy-style bar to count down buzz-in time
