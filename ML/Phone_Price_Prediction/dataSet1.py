import pandas as pd
import numpy as np
import random

# تحديد عدد الأجهزة
num_devices = 500000  # يمكنك تغيير الرقم حسب الحاجة

# بيانات الماركات والموديلات (عينات)
brands = ["Apple", "Samsung", "Google", "OnePlus", "Xiaomi", "Oppo", "Huawei"]
models = ["Pro", "Max", "Ultra", "Lite", "Note", "Plus", "T"]

# معالجات مرتبطة بالعلامات التجارية
brand_cpus = {
    "Apple": ["A14 Bionic", "A15 Bionic", "A16 Bionic"],
    "Samsung": ["Exynos 990", "Exynos 2100", "Snapdragon 8 Gen 2"],
    "Google": ["Google Tensor", "Google Tensor G2"],
    "OnePlus": ["Snapdragon 865", "Snapdragon 888", "Snapdragon 8 Gen 1"],
    "Xiaomi": ["Snapdragon 732G", "Snapdragon 870", "Snapdragon 8+ Gen 1"],
    "Oppo": ["Dimensity 8100", "Snapdragon 778G", "Snapdragon 8 Gen 1"],
    "Huawei": ["Kirin 9000", "Kirin 990", "Dimensity 8000"]
}

screen_types = ["LCD", "OLED", "AMOLED"]

# إنشاء بيانات عشوائية ولكن واقعية
data = []
for _ in range(num_devices):
    brand = random.choice(brands)
    model = f"{brand} {random.choice(models)} {random.randint(1, 20)}"
    release_year = random.randint(2018, 2024)
    release_date = f"{release_year}"
    cpu = random.choice(brand_cpus[brand])
    ram = random.choice([4, 6, 8, 12, 16]) if brand != "Apple" else random.choice([4, 6])
    storage = random.choice([64, 128, 256, 512]) if brand != "Apple" else random.choice([128, 256, 512])
    screen_size = round(np.random.normal(6.5, 0.5), 2)  # متوسط 6.5 إنش
    screen_type = random.choice(screen_types)
    camera = random.choice([12, 48, 50, 64, 108])  # ميغابكسل
    battery = random.choice([3000, 4000, 4500, 5000, 6000]) if brand != "Apple" else random.choice([2815, 3227, 3687])
    
    # حساب سعر الإطلاق بناءً على المواصفات والبراند
    base_price = 250 if brand in ["Apple", "Samsung"] else 150
    base_price += ram * 15
    base_price += (storage / 64) * 40
    base_price += (screen_size - 5) * 25
    base_price += camera * 1.5
    base_price += (battery / 1000) * 30
    if screen_type == "AMOLED":
        base_price += 80
    if "Pro" in model or "Ultra" in model:
        base_price += 100
    launch_price = round(base_price, 2)
    
    # حساب السعر الحالي بناءً على العمر مع تأثير التراجع الطبيعي
    years_old = 2025 - release_year
    depreciation_rate = 0.15 if brand in ["Apple", "Samsung"] else 0.20
    depreciation = min(launch_price * depreciation_rate * years_old, launch_price * 0.80)  # انخفاض السعر سنويًا
    current_price = round(max(launch_price - depreciation, 50), 2)
    
    # توقع الأسعار بعد 3، 6، 9، و 12 شهرًا
    monthly_depreciation_rate = depreciation_rate / 12
    price_after_3_months = round(max(current_price * (1 - monthly_depreciation_rate * 3), 50), 2)
    price_after_6_months = round(max(current_price * (1 - monthly_depreciation_rate * 6), 50), 2)
    price_after_9_months = round(max(current_price * (1 - monthly_depreciation_rate * 9), 50), 2)
    price_after_12_months = round(max(current_price * (1 - monthly_depreciation_rate * 12), 50), 2)
    
    data.append([brand, model, release_date, cpu, ram, storage, screen_size, screen_type, camera, battery, launch_price, current_price, price_after_3_months, price_after_6_months, price_after_9_months, price_after_12_months])

# إنشاء DataFrame
columns = ["Brand", "Model", "Release Date", "CPU", "RAM (GB)", "Storage (GB)", "Screen Size (inches)", "Screen Type", "Camera (MP)", "Battery (mAh)", "Launch Price (USD)", "Current Price (USD)", "Price After 3 Months (USD)", "Price After 6 Months (USD)", "Price After 9 Months (USD)", "Price After 12 Months (USD)"]
df = pd.DataFrame(data, columns=columns)

# حفظ البيانات في ملف CSV
file_path = "device_prices_realistic.csv"
df.to_csv(file_path, index=False)
print(f"Dataset saved as {file_path}")
