import pandas as pd

DATA_PATH = '../../../db/data/combined_season1-39.tsv'
CLEAN_DATA_PATH = '../../../db/data/combined_season1-39_clean.tsv'

# Import, clean, write out clean data
data = pd.read_csv(DATA_PATH, sep='\t', quoting=3)
data = data.apply(
    lambda x: x.str.strip().str.strip('"') if x.dtype == 'object' else x)
data.to_csv(CLEAN_DATA_PATH, sep='\t', index=False, quoting=3)
clean = pd.read_csv(CLEAN_DATA_PATH, sep='\t', quoting=3)
