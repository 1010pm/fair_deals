from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import tensorflow as tf
import pickle
import joblib
import numpy as np
import pandas as pd
from typing import List
from tensorflow.keras.preprocessing.sequence import pad_sequences
from xgboost import XGBClassifier

# Initialize FastAPI app
app = FastAPI()

# ====================== Sentiment Analysis Section ======================
# Load Sentiment Analysis Model (LSTM)
model_sentiment = tf.keras.models.load_model("sentiment_lstm.h5")

# Load Tokenizer for Sentiment Analysis
with open("tokenizer.pkl", "rb") as handle:
    tokenizer = pickle.load(handle)

# Request and Response Models
class SentimentAnalysisRequest(BaseModel):
    text: str

class SentimentResponse(BaseModel):
    sentiment: str
    confidence: float

# Function for sentiment analysis
def predict_sentiment(text: str, model, tokenizer, max_len=50):
    sequence = tokenizer.texts_to_sequences([text])
    padded_sequence = pad_sequences(sequence, maxlen=max_len)
    
    prediction = model.predict(padded_sequence)[0][0]
    sentiment = "Positive" if prediction > 0.5 else "Negative"
    confidence = prediction if prediction > 0.5 else 1 - prediction
    
    return sentiment, confidence

# API Endpoint for Sentiment Analysis
@app.post("/predict_sentiment/", response_model=SentimentResponse)
def get_predicted_sentiment(request: SentimentAnalysisRequest):
    sentiment, confidence = predict_sentiment(request.text, model_sentiment, tokenizer)
    return SentimentResponse(sentiment=sentiment, confidence=confidence)

# ====================== Product Deal Prediction Section ======================
# Load Product Deal Prediction Model and Encoders
xgb_model = XGBClassifier()
xgb_model.load_model('best_xgb_model.json')  # Load model saved as JSON

le_product = joblib.load('product_encoder.pkl')
le_deal = joblib.load('deal_encoder.pkl')

# Input Models
class ProductInput(BaseModel):
    product: str
    price: float
    distance: float

class ProductList(BaseModel):
    items: List[ProductInput]

# Prediction endpoint
@app.post("/predict_deal")
def predict_bulk(data: ProductList):
    sample_data = [item.dict() for item in data.items]
    df_sample = pd.DataFrame(sample_data)
    avg_price_dict = df_sample.groupby('product')['price'].mean().to_dict()
    
    predictions = []
    
    for data in sample_data:
        product_name = data['product']
        price = data['price']
        distance = data['distance']
        
        # Handle unknown products
        if product_name not in le_product.classes_:
            predictions.append({"product": product_name, "price": price, "distance": distance, "prediction": "Unknown Product"})
            continue
        
        product_encoded = le_product.transform([product_name])[0]
        avg_price = avg_price_dict.get(product_name, price)
        price_deviation = (price - avg_price) / avg_price
        price_per_distance = price / (distance + 1)
        
        input_data = pd.DataFrame([{
            'product_encoded': product_encoded, 
            'price': price, 
            'distance': distance, 
            'avg_price': avg_price, 
            'price_deviation': price_deviation, 
            'price_per_distance': price_per_distance
        }])
        
        # Make prediction
        prediction_encoded = xgb_model.predict(input_data)[0]
        predicted_deal = le_deal.inverse_transform([prediction_encoded])[0]
        
        if predicted_deal == 'Good' and price_deviation < -0.1:
            predicted_deal = 'Excellent'
        elif predicted_deal == 'Fair' and price_deviation > 0.1:
            predicted_deal = 'Bad'
        
        predictions.append({"product": product_name, "price": price, "distance": distance, "prediction": predicted_deal})
    
    return {"predictions": predictions}

# ====================== Device Price Prediction Section ======================
# Load Device Price Prediction Model
device_model = joblib.load("device_price_prediction_model_xgb.pkl")

# Expected columns after One-Hot Encoding
expected_columns = [
    'RAM (GB)', 'Storage (GB)', 'Screen Size (inches)', 'Camera (MP)', 'Battery (mAh)', 
    'Current Price (USD)', 
    'Brand_Google', 'Brand_Huawei', 'Brand_OnePlus', 'Brand_Oppo', 'Brand_Samsung', 'Brand_Xiaomi', 
    'CPU_A15 Bionic', 'CPU_A16 Bionic', 'CPU_Dimensity 8000', 'CPU_Dimensity 8100', 'CPU_Exynos 2100', 
    'CPU_Exynos 990', 'CPU_Google Tensor', 'CPU_Google Tensor G2', 'CPU_Kirin 9000', 'CPU_Kirin 990', 
    'CPU_Snapdragon 732G', 'CPU_Snapdragon 778G', 'CPU_Snapdragon 8 Gen 1', 'CPU_Snapdragon 8 Gen 2', 
    'CPU_Snapdragon 8+ Gen 1', 'CPU_Snapdragon 865', 'CPU_Snapdragon 870', 'CPU_Snapdragon 888', 
    'Screen Type_LCD', 'Screen Type_OLED'
]

# Input Model
class DeviceInput(BaseModel):
    RAM_GB: int
    Storage_GB: int
    Screen_Size_inches: float
    Camera_MP: int
    Battery_mAh: int
    Current_Price_USD: float
    Brand: str
    CPU: str
    Screen_Type: str

@app.post("/predict_device_price")
def predict_price(device: DeviceInput):
    try:
        # Convert input to DataFrame
        input_data = {
            "RAM (GB)": device.RAM_GB,
            "Storage (GB)": device.Storage_GB,
            "Screen Size (inches)": device.Screen_Size_inches,
            "Camera (MP)": device.Camera_MP,
            "Battery (mAh)": device.Battery_mAh,
            "Current Price (USD)": device.Current_Price_USD,
            "Brand": device.Brand,
            "CPU": device.CPU,
            "Screen Type": device.Screen_Type,
        }
        input_df = pd.DataFrame([input_data])
        
        # Apply One-Hot Encoding
        input_df = pd.get_dummies(input_df)
        
        # Ensure all expected columns are present
        for col in expected_columns:
            if col not in input_df.columns:
                input_df[col] = 0  # Fill missing columns with zero
        
        # Order columns as expected by the model
        input_df = input_df[expected_columns]
        
        # Make prediction
        prediction = device_model.predict(input_df)
        predicted_prices = prediction.flatten().tolist()  # Convert NumPy array to a standard Python list

        return {
            "3_months": float(predicted_prices[0]),
            "6_months": float(predicted_prices[1]),
            "9_months": float(predicted_prices[2]),
            "12_months": float(predicted_prices[3])
        }

    except Exception as e:
        raise HTTPException(status_code=400, detail=str(e))

# Run the FastAPI server using:
# uvicorn combined_api:app --reload