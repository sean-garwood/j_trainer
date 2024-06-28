import pandas as pd

# Function to map categories to subjects
def map_category_to_subject(category):
    category = category.upper()  # Ensure case consistency
    return category if category in KEY_CATEGORIES else ''

CLEAN_DATA_PATH = '../../../db/data/combined_season1-39_clean.tsv'
KEY_CATEGORIES = [
    'ARTS', 'HISTORY', 'GEOGRAPHY', 'LITERATURE', 'SCIENCE', 'ENTERTAINMENT',
    'MUSIC', 'POP CULTURE', 'SPORTS', 'WORDS & PHRASES', 'POTPURRI',
    'HODGEPODGE']
SUBJECT_FEATURES = ['category', 'question', 'answer']

data = pd.read_csv(CLEAN_DATA_PATH, sep='\t', quoting=3)
# drop irrelevant columns
data = data[SUBJECT_FEATURES]
# Apply the mapping to create a new 'subject' column
data['subject'] = data['category'].apply(map_category_to_subject(data['category']))
