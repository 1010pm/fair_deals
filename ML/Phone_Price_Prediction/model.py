import pandas as pd
import numpy as np
from sklearn.model_selection import train_test_split, RandomizedSearchCV
from sklearn.metrics import mean_squared_error
from xgboost import XGBRegressor
import joblib

# قراءة الداتا
df = pd.read_csv("device_prices_realistic.csv")

# تجهيز الأعمدة المستهدفة (Target)
price_targets = [
    "Price After 3 Months (USD)",
    "Price After 6 Months (USD)",
    "Price After 9 Months (USD)",
    "Price After 12 Months (USD)"
]

# تحويل النصوص إلى أرقام باستخدام One Hot Encoding
df = pd.get_dummies(df, columns=["Brand", "CPU", "Screen Type"], drop_first=True)

# تحديد الـ Features (كل شيء ما عدا الأعمدة المستهدفة)
# حذف "Launch Price (USD)" من الأعمدة المدخلة
X = df.drop(columns=price_targets + ['Model', 'Release Date', 'Launch Price (USD)'])  # حذف العمود "Launch Price (USD)"
y = df[price_targets]

# تقسيم البيانات
X_train, X_test, y_train, y_test = train_test_split(
    X, y, test_size=0.2, random_state=42
)

# بناء نموذج XGBoost
model = XGBRegressor(
    random_state=42,
    tree_method='gpu_hist',  # استخدام GPU
    gpu_id=0,  # تأكد من أن رقم الـ GPU صحيح إذا كان لديك أكثر من واحد
)


# ضبط المعاملات باستخدام RandomizedSearchCV
param_dist = {
    "n_estimators": [100, 200, 300],
    "max_depth": [3, 4, 5],
    "learning_rate": [0.01, 0.05, 0.1],
    "subsample": [0.8, 0.9, 1.0],
}

random_search = RandomizedSearchCV(
    model, param_distributions=param_dist, n_iter=10, cv=3, random_state=42, n_jobs=-1
)

# تدريب النموذج
random_search.fit(X_train, y_train)

# التنبؤ على بيانات الاختبار
y_pred = random_search.best_estimator_.predict(X_test)

# حساب الـ MSE لكل فترة زمنية
mse = mean_squared_error(y_test, y_pred, multioutput='raw_values')
for i, period in enumerate(price_targets):
    print(f"Mean Squared Error for {period}: {mse[i]:.2f}")

# حفظ النموذج النهائي
joblib.dump(random_search.best_estimator_, "device_price_prediction_model_xgb.pkl")
print("✅ تم حفظ النموذج بنجاح!")
