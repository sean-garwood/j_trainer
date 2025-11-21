# Normalized clue values for Jeopardy! rounds
# These values were standardized on 11/26/2001
NORMALIZED_JEOPARDY_CLUE_VALUES = {
  round_1: [ 200, 400, 600, 800, 1000 ],
  round_2: [ 400, 800, 1200, 1600, 2000 ]
}.freeze

ALL_CLUE_VALUES = (NORMALIZED_JEOPARDY_CLUE_VALUES[:round_1] + NORMALIZED_JEOPARDY_CLUE_VALUES[:round_2]).uniq.sort.freeze
