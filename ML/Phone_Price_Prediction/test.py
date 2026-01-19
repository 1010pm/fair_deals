
import joblib
import pandas as pd

# تحميل النموذج
model = joblib.load("device_price_prediction_model_xgb.pkl")
print("✅ تم تحميل النموذج بنجاح!")

# الأعمدة المتوقعة في البيانات المدخلة بعد One-Hot Encoding
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

# نموذج الإدخال اليدوي (مثال):
manual_input = {
    "RAM (GB)": 6,
    "Storage (GB)": 128,
    "Screen Size (inches)": 3.52,
    "Camera (MP)": 64,
    "Battery (mAh)": 4500,
    "Current Price (USD)": 452,  # تم حذف "Launch Price (USD)"
    "Brand": "Xiaomi",  # تأكد من أن الاسم يطابق العلامة التجارية
    "CPU": "Snapdragon 870",  # تأكد من أن اسم المعالج يطابق البيانات
    "Screen Type": "LCD"  # تأكد من نوع الشاشة
}

# تحويل الإدخال إلى DataFrame
input_df = pd.DataFrame([manual_input])

# تحويل النصوص إلى أرقام باستخدام One Hot Encoding (مثلًا 'Brand', 'CPU', 'Screen Type')
input_df = pd.get_dummies(input_df)

# التأكد من أن الأعمدة المتوقعة موجودة في البيانات المدخلة
for col in expected_columns:
    if col not in input_df.columns:
        input_df[col] = 0  # إضافة العمود بالقيمة صفر إذا لم يكن موجودًا

# ترتيب الأعمدة بالترتيب المتوقع
input_df = input_df[expected_columns]

# التنبؤ باستخدام النموذج
prediction = model.predict(input_df)

# عرض التنبؤ بالأسعار المستقبلية
print("✅ التنبؤ بالأسعار المستقبلية:")
print(f"بعد 3 أشهر: {prediction[0][0]:.2f} USD")
print(f"بعد 6 أشهر: {prediction[0][1]:.2f} USD")
print(f"بعد 9 أشهر: {prediction[0][2]:.2f} USD")
print(f"بعد 12 شهر: {prediction[0][3]:.2f} USD")






