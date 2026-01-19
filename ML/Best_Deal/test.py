import joblib
import numpy as np
import pandas as pd
from sklearn.preprocessing import LabelEncoder
from sklearn.metrics import classification_report

# ✅ تحميل النموذج والمشفرات
xgb_model = joblib.load('best_xgb_model.pkl')
le_product = joblib.load('product_encoder.pkl')
le_deal = joblib.load('deal_encoder.pkl')

# ✅ تعريف بيانات الاختبار
sample_data = [
    {'product': 'iPhone 13', 'price': 150, 'distance': 5},   
    {'product': 'iPhone 13', 'price': 100, 'distance': 10},  
    {'product': 'iPhone 13', 'price': 140, 'distance': 50},  
    {'product': 'iPhone 13', 'price': 165, 'distance': 10},  
    {'product': 'iPhone 13', 'price': 150, 'distance': 2},   

    {'product': 'Galaxy S23', 'price': 370, 'distance': 15},  
    {'product': 'Galaxy S23', 'price': 390, 'distance': 40},  
    {'product': 'Galaxy S23', 'price': 420, 'distance': 5},  

    {'product': 'iPhone 12 mini', 'price': 250, 'distance': 20},
    {'product': 'iPhone 12 mini', 'price': 200, 'distance': 12},
    {'product': 'iPhone 12 mini', 'price': 130, 'distance': 10},

    {'product': 'Galaxy S21', 'price': 350, 'distance': 20},
    {'product': 'Pixel 7', 'price': 345, 'distance': 15},
    {'product': 'Redmi Note 10', 'price': 125, 'distance': 25},
    {'product': 'Galaxy Z Flip5', 'price': 250, 'distance': 7},
    {'product': 'iPhone 15 Pro Max', 'price': 380, 'distance': 5},
]

# ✅ حساب متوسط الأسعار بناءً على البيانات الحالية
df_sample = pd.DataFrame(sample_data)
avg_price_dict = df_sample.groupby('product')['price'].mean().to_dict()

# 📌 دالة التنبؤ
def predict_bulk(data_list):
    predictions = []
    
    for data in data_list:
        product_name = data['product']
        price = data['price']
        distance = data['distance']
        
        # التعامل مع المنتجات غير المعروفة
        if product_name not in le_product.classes_:
            predictions.append({'product': product_name, 'price': price, 'distance': distance, 'prediction': 'Unknown Product'})
            continue
        
        product_encoded = le_product.transform([product_name])[0]
        avg_price = avg_price_dict.get(product_name, price)  # استخدم متوسط الحساب الجديد

        # حساب price_deviation و price_per_distance
        price_deviation = (price - avg_price) / avg_price
        price_per_distance = price / (distance + 1)  # تجنب القسمة على صفر
        
        # **تحويل البيانات إلى DataFrame بالاسم الصحيح للأعمدة**
        input_data = pd.DataFrame([{
            'product_encoded': product_encoded, 
            'price': price, 
            'distance': distance, 
            'avg_price': avg_price, 
            'price_deviation': price_deviation, 
            'price_per_distance': price_per_distance
        }])

        # ✅ التنبؤ
        prediction_encoded = xgb_model.predict(input_data)[0]
        predicted_deal = le_deal.inverse_transform([prediction_encoded])[0]
        
        # تحسين التصنيف: إضافة رسالة حول ما إذا كان السعر مميزًا بناءً على الفئة
        if predicted_deal == 'Good' and price_deviation < -0.1:
            predicted_deal = 'Excellent'
        elif predicted_deal == 'Fair' and price_deviation > 0.1:
            predicted_deal = 'Bad'
        
        # حفظ النتيجة
        predictions.append({'product': product_name, 'price': price, 'distance': distance, 'prediction': predicted_deal})
    
    return predictions

# ✅ تنفيذ التنبؤات
results = predict_bulk(sample_data)

# 📌 طباعة النتائج
for result in results:
    print(result)

