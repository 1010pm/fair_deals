# -*- coding: utf-8 -*-
"""
Load the trained sentiment analysis model and test it.
"""

import tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences
import pickle

# ========== 1. Load the Model ==========
model = tf.keras.models.load_model("sentiment_lstm.h5")
print("✅ Model loaded successfully!")

# ========== 2. Load Tokenizer ==========
with open("tokenizer.pkl", "rb") as handle:
    tokenizer = pickle.load(handle)

print("✅ Tokenizer loaded successfully!")

# ========== 3. Sentiment Prediction Function ==========
def predict_sentiment(text, model, tokenizer, max_len=50):
    # Convert text to sequences
    sequence = tokenizer.texts_to_sequences([text])
    padded_sequence = pad_sequences(sequence, maxlen=max_len)

    # Predict sentiment
    prediction = model.predict(padded_sequence)[0][0]

    # Interpret result
    sentiment = "Positive" if prediction > 0.5 else "Negative"
    confidence = prediction if prediction > 0.5 else 1 - prediction
    return sentiment, confidence



# ========== 4. Test Model ==========
test_texts = [
    # Positive feedback
    "I love this product, it's amazing!",
    "Absolutely fantastic! Highly recommend.",
    "Great value for the price, very satisfied.",
    "The quality exceeded my expectations!",
    "Fast delivery and excellent customer service.",
    "This store always delivers high-quality products.",
    "The best purchase I've made this year!",
    "I'm impressed with the durability of this item.",
    "Highly reliable brand, will buy again.",
    "Smooth transaction, very professional service.",
    
    # Negative feedback
    "This is the worst experience I've ever had.",
    "Terrible service, never buying again.",
    "The product broke within a week, very disappointed.",
    "Extremely slow shipping, took over a month to arrive.",
    "Customer service was rude and unhelpful.",
    "Not as described, a complete waste of money.",
    "The quality is awful, feels very cheap.",
    "I wouldn't recommend this to anyone.",
    "Overpriced for what you get, very disappointed.",
    "Defective item received, had to return it."
]


for text in test_texts:
    sentiment, confidence = predict_sentiment(text, model, tokenizer)
    print(f"Text: {text}\nSentiment: {sentiment} (Confidence: {confidence:.2f})\n")
