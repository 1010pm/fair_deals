from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import joblib
import pandas as pd
import numpy as np
import tensorflow as tf
from tensorflow.keras.preprocessing.sequence import pad_sequences
import pickle
from sklearn.preprocessing import LabelEncoder, MinMaxScaler

# 🌟 Initialize FastAPI app
app = FastAPI()

# 🔹 Load models
print("Loading models...")

# Price Prediction Model (XGBoost)
model_price = joblib.load("price_prediction_model_xgb.pkl")
train_columns = model_price.feature_names_in_

# Deal Classification Model (Keras)
model_deal = tf.keras.models.load_model("best_deal_improved.keras")

# Sentiment Analysis Model (LSTM)
model_sentiment = tf.keras.models.load_model("sentiment_lstm.h5")

# Load Tokenizer for Sentiment Analysis
with open("tokenizer.pkl", "rb") as handle:
    tokenizer = pickle.load(handle)

# 🔹 Product price ranges used in training
product_price_ranges = {
    # Apple iPhones
    "iPhone SE (2nd generation)": (70, 150),
    "iPhone 12 mini": (120, 150),
    "iPhone 12": (130, 160),
    "iPhone 12 Pro": (159, 180),
    "iPhone 12 Pro Max": (189, 230),
    "iPhone 13 mini": (130, 155),
    "iPhone 13": (149, 160),
    "iPhone 13 Pro": (199, 240),
    "iPhone 13 Pro Max": (220, 260),
    "iPhone SE (3rd generation)": (200, 240),
    "iPhone 14": (190, 250),
    "iPhone 14 Plus": (195, 230),
    "iPhone 14 Pro": (265, 290),
    "iPhone 14 Pro Max": (275, 320),
    "iPhone 15": (225, 260),
    "iPhone 15 Plus": (249, 289),
    "iPhone 15 Pro": (300, 350),
    "iPhone 15 Pro Max": (360, 400),
    "iPhone 16": (350, 380),  # Estimated
    "iPhone 16 Plus": (389, 400),  # Estimated
    "iPhone 16 Pro": (395, 420),  # Estimated
    "iPhone 16 Pro Max": (440, 460),  # Estimated
    "iPhone 16e": (300, 350),  # Estimated

    # Samsung Galaxy Series
    "Galaxy S20": (300, 350),
    "Galaxy S20+": (350, 400),
    "Galaxy S20 Ultra": (450, 500),
    "Galaxy Note20": (400, 450),
    "Galaxy Note20 Ultra": (500, 550),
    "Galaxy Z Fold2": (700, 800),
    "Galaxy S20 FE": (250, 300),
    "Galaxy S21": (320, 370),
    "Galaxy S21+": (370, 420),
    "Galaxy S21 Ultra": (470, 520),
    "Galaxy Z Fold3": (750, 850),
    "Galaxy Z Flip3": (600, 700),
    "Galaxy S22": (340, 390),
    "Galaxy S22+": (390, 440),
    "Galaxy S22 Ultra": (490, 540),
    "Galaxy Z Fold4": (800, 900),
    "Galaxy Z Flip4": (650, 750),
    "Galaxy S23": (360, 410),
    "Galaxy S23+": (410, 460),
    "Galaxy S23 Ultra": (510, 560),
    "Galaxy Z Fold5": (850, 950),
    "Galaxy Z Flip5": (700, 800),
    "Galaxy S24": (380, 430),  # Estimated
    "Galaxy S24+": (430, 480),  # Estimated
    "Galaxy S24 Ultra": (530, 580),  # Estimated
    "Galaxy Z Fold6": (900, 1000),  # Estimated
    "Galaxy Z Flip6": (750, 850),  # Estimated
    "Galaxy S25": (400, 450),  # Estimated
    "Galaxy S25+": (450, 500),  # Estimated
    "Galaxy S25 Ultra": (550, 600),  # Estimated
    "Galaxy S25 Edge": (600, 650),  # Estimated

    # Google Pixel Series
    "Pixel 4a": (180, 220),
    "Pixel 4a (5G)": (220, 260),
    "Pixel 5": (300, 340),
    "Pixel 5a": (240, 280),
    "Pixel 6": (320, 360),
    "Pixel 6 Pro": (400, 440),
    "Pixel 6a": (260, 300),
    "Pixel 7": (340, 380),
    "Pixel 7 Pro": (420, 460),
    "Pixel 7a": (280, 320),
    "Pixel Fold": (700, 800),
    "Pixel 8": (360, 400),
    "Pixel 8 Pro": (440, 480),
    "Pixel 8a": (300, 340),  # Estimated
    "Pixel 9": (380, 420),  # Estimated
    "Pixel 9 Pro": (460, 500),  # Estimated

    # Xiaomi Mi and Redmi Series
    "Mi 10": (300, 350),
    "Mi 10 Pro": (350, 400),
    "Redmi Note 9": (100, 150),
    "Redmi Note 9 Pro": (150, 200),
    "Mi 11": (400, 450),
    "Mi 11 Ultra": (500, 550),
    "Redmi Note 10": (120, 170)
}

# 🔹 Label Encoder for product names
label_encoder = LabelEncoder()
label_encoder.fit(list(product_price_ranges.keys()))

# 🔹 MinMaxScaler for distance normalization
scaler_distance = MinMaxScaler()
scaler_distance.fit(np.array([[0], [70]]))

# 🔹 Price normalization parameters
MIN_PRICE, MAX_PRICE = 50, 2500  # Adjust based on dataset range


# 📌 Request Models
class PricePredictionRequest(BaseModel):
    brand: str
    launched_price: float


class DealPredictionRequest(BaseModel):
    product_name: str
    price: float
    distance: float


class SentimentAnalysisRequest(BaseModel):
    text: str


class SentimentResponse(BaseModel):
    sentiment: str
    confidence: float

 
#📌 Function to predict price over time
def predict_price(brand: str, launched_price: float):
    # إنشاء DataFrame جديد بالإدخال
    product_data = {'Launched Price (OMR)': [launched_price]}

    # إضافة الأعمدة الخاصة بالعلامات التجارية بناءً على One Hot Encoding
    for col in train_columns:
        if "Brand_" in col:
            product_data[col] = [1 if col == f"Brand_{brand}" else 0]

    # تحويل البيانات إلى DataFrame
    new_data = pd.DataFrame(product_data)

    # التأكد من تطابق ترتيب الأعمدة
    new_data = new_data[train_columns]

    # توقع الأسعار المستقبلية
    predicted_prices = model_price.predict(new_data)

    return {
        "Price After 3 Months": f"{predicted_prices[0][0]:.2f} OMR",
        "Price After 6 Months": f"{predicted_prices[0][1]:.2f} OMR",
        "Price After 9 Months": f"{predicted_prices[0][2]:.2f} OMR",
        "Price After 12 Months": f"{predicted_prices[0][3]:.2f} OMR"
    }


# 📌 Function to classify deal quality
def predict_deal(product_name: str, price: float, distance: float):
    if product_name not in product_price_ranges:
        raise HTTPException(status_code=400, detail="Product not found in training data.")

    avg_price = np.mean(product_price_ranges[product_name])
    price_deviation = (price - avg_price) / avg_price
    product_encoded = label_encoder.transform([product_name])[0]
    distance_norm = scaler_distance.transform([[distance]])[0][0]

    # Prepare input
    X_test = np.array([[product_encoded, price_deviation, distance_norm]])

    # Get prediction
    prediction = model_deal.predict([X_test[:, 0], X_test[:, 1:]])
    label = np.argmax(prediction)

    # Map prediction to deal categories
    deal_map = {0: "Excellent Deal", 1: "Good Deal", 2: "Bad Deal"}
    return {"deal": deal_map[label]}


# 📌 Function for sentiment analysis
def predict_sentiment(text: str, model, tokenizer, max_len=50):
    sequence = tokenizer.texts_to_sequences([text])
    padded_sequence = pad_sequences(sequence, maxlen=max_len)

    prediction = model.predict(padded_sequence)[0][0]
    sentiment = "Positive" if prediction > 0.5 else "Negative"
    confidence = prediction if prediction > 0.5 else 1 - prediction

    return sentiment, confidence


# 📌 API Endpoints

@app.post("/predict_price/")
def get_predicted_price(request: PricePredictionRequest):
    return predict_price(request.brand, request.launched_price)


@app.post("/predict_deal/")
def get_predicted_deal(request: DealPredictionRequest):
    return predict_deal(request.product_name, request.price, request.distance)


@app.post("/predict_sentiment/", response_model=SentimentResponse)
def get_predicted_sentiment(request: SentimentAnalysisRequest):
    sentiment, confidence = predict_sentiment(request.text, model_sentiment, tokenizer)
    return SentimentResponse(sentiment=sentiment, confidence=confidence)


# ✅ Run the FastAPI server using:
#     uvicorn fastapi_app:app --reload
