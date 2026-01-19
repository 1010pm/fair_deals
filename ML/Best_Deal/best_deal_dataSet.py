import pandas as pd
import numpy as np

# القاموس الذي يحتوي على الأجهزة ونطاق أسعارها
product_price_ranges =  {
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

# عدد العينات# عدد العينات
num_samples = 5_000_000  
np.random.seed(42)

# توليد البيانات العشوائية
products = np.random.choice(list(product_price_ranges.keys()), num_samples)
prices = np.array([
    round(np.random.uniform(low=product_price_ranges[product][0], high=product_price_ranges[product][1]), 2)
    for product in products
])

# توزيع المسافات بشكل أكثر واقعية
distances = np.round(np.random.exponential(scale=15, size=num_samples), 2)
distances = np.clip(distances, 0, 70)

# إنشاء DataFrame
df = pd.DataFrame({'product': products, 'price': prices, 'distance': distances})

# حساب متوسط السعر لكل منتج بطريقة أكثر كفاءة
avg_price_dict = {product: np.mean([low, high]) for product, (low, high) in product_price_ranges.items()}
df['avg_price'] = df['product'].map(avg_price_dict)

# حساب الانحراف السعري
df['price_deviation'] = (df['price'] - df['avg_price']) / df['avg_price']

# تحسين التصنيف باستخدام numpy
df['deal'] = np.where(
    (df['price_deviation'] < -0.2) & (df['distance'] <= 25), 'Excellent',
    np.where(
        (df['price_deviation'] < -0.1) | ((df['price_deviation'] < 0) & (df['distance'] <= 50)), 'Good',
        np.where(
            (df['price_deviation'] < 0.1), 'Fair',
            'Bad'
        )
    )
)

# حفظ البيانات النهائية مع التصنيف
df.to_csv('classified_products.csv', index=False, encoding='utf-8-sig')

print("✅ تم إنشاء ملف classified_products.csv مع التصنيف بنجاح!")