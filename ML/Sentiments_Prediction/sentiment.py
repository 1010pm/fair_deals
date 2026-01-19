import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.text import Tokenizer
from tensorflow.keras.preprocessing.sequence import pad_sequences
from tensorflow.keras.models import Sequential
from tensorflow.keras.layers import Embedding, LSTM, Dense, Dropout
from sklearn.model_selection import train_test_split

# Load dataset

columns = ['target', 'id', 'date', 'flag', 'user', 'text']
df = pd.read_csv('sentiment140.csv', encoding='latin-1', names=columns)

# Keep only relevant columns
df = df[['target', 'text']] 
df['target'] = df['target'].map({0: 0, 4: 1})  # Convert target to binary (0 = negative, 1 = positive)

# Preprocessing
max_words = 20000  # Maximum number of words in the vocabulary
max_len = 50       # Maximum length of sequences

# Tokenization
tokenizer = Tokenizer(num_words=max_words, oov_token="<OOV>")
tokenizer.fit_on_texts(df['text'])
sequences = tokenizer.texts_to_sequences(df['text'])
X = pad_sequences(sequences, maxlen=max_len)
y = np.array(df['target'])

# Train-test split
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42)

# LSTM Model
model = Sequential([
    Embedding(max_words, 128, input_length=max_len),
    LSTM(64, return_sequences=True),
    Dropout(0.2),
    LSTM(32),
    Dense(1, activation='sigmoid')
])

# Compile model
model.compile(loss='binary_crossentropy', optimizer='adam', metrics=['accuracy'])

# Train model
model.fit(X_train, y_train, validation_data=(X_test, y_test), epochs=3, batch_size=64)

# Save model
model.save("sentiment_lstm.h5")

print("Model training complete and saved as sentiment_lstm.h5")
