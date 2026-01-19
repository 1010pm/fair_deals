import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, StratifiedKFold
from sklearn.preprocessing import LabelEncoder
from xgboost import XGBClassifier
from sklearn.metrics import classification_report
import joblib
import warnings
warnings.filterwarnings('ignore')

# 📌 قراءة البيانات
df = pd.read_csv('balanced_classified_products.csv')

# 📌 ترميز الأعمدة النصية
le_product = LabelEncoder()
le_deal = LabelEncoder()
df['product_encoded'] = le_product.fit_transform(df['product'])
df['deal_encoded'] = le_deal.fit_transform(df['deal'])  # Excellent = 0, Good = 1, Fair = 2, Bad = 3

# ✅ إنشاء ميزة جديدة لتحسين التوقعات
df['price_per_distance'] = df['price'] / (df['distance'] + 1)  # تجنب القسمة على صفر

# 📌 تحديد الميزات والهدف
features = ['product_encoded', 'price', 'distance', 'avg_price', 'price_deviation', 'price_per_distance']
X = df[features]
y = df['deal_encoded']

# 📌 تقسيم البيانات إلى تدريب واختبار
X_train, X_test, y_train, y_test = train_test_split(X, y, test_size=0.2, random_state=42, stratify=y)

# 🔥 إعداد XGBoost مع GPU
xgb = XGBClassifier(
    objective='multi:softmax',
    num_class=4,  # عدد الفئات
    tree_method='gpu_hist',  # استخدام GPU
    predictor='gpu_predictor',
    eval_metric='mlogloss',
    n_estimators=300,  # عدد الأشجار
    max_depth=10,  # عمق الأشجار
    learning_rate=0.1,
    subsample=0.8,
    colsample_bytree=0.8,
    random_state=42
)

# ✅ تدريب النموذج
xgb.fit(X_train, y_train)

# 📌 التقييم على بيانات الاختبار
y_pred_xgb = xgb.predict(X_test)
print("\n🔥 تقرير XGBoost:")
print(classification_report(y_test, y_pred_xgb))

# ✅ حفظ النموذج والـ encoders
xgb.save_model('best_xgb_model.json')

joblib.dump(le_product, 'product_encoder.pkl')
joblib.dump(le_deal, 'deal_encoder.pkl')
print("✅ تم حفظ النموذج والـ Encoders بنجاح!")
