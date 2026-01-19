# -*- coding: utf-8 -*-
"""
Created on Thu Mar 27 13:26:29 2025

@author: USER
"""

import pandas as pd
import numpy as np

# تحميل البيانات المصنفة
df = pd.read_csv('classified_products.csv')

# التحقق من توزيع الفئات
class_counts = df['deal'].value_counts()
min_count = class_counts.min()  # أخذ أقل عدد من العينات المتاحة في أي فئة

# موازنة الفئات عبر أخذ عينات متساوية
balanced_df = df.groupby('deal').apply(lambda x: x.sample(min_count, random_state=42)).reset_index(drop=True)

# حفظ البيانات المتوازنة
balanced_df.to_csv('balanced_classified_products.csv', index=False, encoding='utf-8-sig')

print("✅ تم إنشاء ملف balanced_classified_products.csv مع توزيع متساوٍ للفئات!")
