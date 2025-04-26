# J! Trainer

Hone your Jeopardy! skills using real clues from the game. Inspired by
[Protobowl](https://protobowl.com/jeopardy/lobby).

## Features

This app is under construction. It doesn't really have any features.

## Roadmap

1. Get some clues!
   - No decent APIs seem to exist. I found a pretty nice static .tsv but need to
     filter/format.
1. Serve random clues, accept user input
   - Judge as correct/incorrect/pass
   - Persist results to database
1. Filter clues by
   - Category
   - Dollar amount
   - Round
1. Stats view
   - Table view by category/right/wrong/pass
   - Overall lifetime score
   - Score by category
   - Heat map
      - Identify maximal opportunity where:
         - Frequency of category is high
         - Efficiency (dollars gained/dollars possible) is low
