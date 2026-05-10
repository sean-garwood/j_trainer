---
name: data-context
description: gives context for J! Trainer's source data.
disable-model-invocation: false
user-invocable: false
---

## Data Source

- Primary data: `db/data/combined_season1-40.tsv`
- Contains real Jeopardy! clues from seasons 1-40
- Format: TSV with columns: round, clue_value, daily_double_value, category, comments, answer, question, air_date, notes
  - Note: In the database, `answer` maps to `clue_text` and `question` maps to `correct_response`

### TSV Schema

```
round                 : Round number (1=Jeopardy, 2=Double Jeopardy, 3=Final Jeopardy)
clue_value           : Dollar value ($100-$2000, varies by era)
daily_double_value   : Wager if Daily Double (0 if not)
category             : Original Jeopardy category name
comments             : Additional notes/context
answer               : The clue text shown to the user (e.g., "River mentioned most often in the Bible")
                       → Maps to `clue_text` in database
question             : The correct response (e.g., "What is the Jordan?")
                       → Maps to `correct_response` in database
air_date             : Original broadcast date (YYYY-MM-DD)
notes                : Additional notes (often empty)
```

Note on field naming: The TSV uses Jeopardy!'s confusing convention where "answer" is the clue text and "question" is the correct response. In our database, we use the more intuitive names `clue_text` (what's shown to the user) and `correct_response` (what the user should answer).

## Data Challenges

1. Escaping: Quotes, backslashes, and special characters are inconsistently escaped
1. Duplicates: May contain duplicate clues across different air dates
1. Formatting: Response format varies ("What is the Jordan?" vs "What is Jordan?" vs "What is The Jordan River?")
1. Missing Data: Some fields may be empty or contain placeholder values
1. Era Variations: Dollar values changed over time ($100-$500 vs $200-$1000)
