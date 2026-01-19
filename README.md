# Fair Deals - Smart Shopping Platform

A comprehensive mobile application that helps users find the best deals on products using AI-powered price prediction and deal classification. The platform connects customers with local shops, provides intelligent price predictions, and analyzes product sentiment.

## 🚀 Features

### For Customers
- **Smart Product Search**: Browse products from local shops with location-based filtering
- **Price Prediction**: Get AI-powered price predictions for devices and products
- **Deal Classification**: Automatically classify deals as Excellent, Good, Fair, or Bad
- **Shop Discovery**: Find nearby shops based on your location
- **Favorites & Notifications**: Save favorite products and receive notifications
- **User Profile**: Manage your profile and preferences

### For Shop Owners
- **Product Management**: Add, edit, and manage your product listings
- **Dashboard**: View analytics and manage your shop
- **Feedback Management**: Respond to customer feedback
- **Subscription Management**: Manage your shop subscription
- **Settings**: Customize shop settings and preferences

### For Administrators
- **Shop Management**: Approve, manage, and monitor all shops
- **Feedback Review**: Review and manage customer feedback
- **Reports & Analytics**: Generate comprehensive reports
- **System Administration**: Full control over the platform

## 🏗️ Architecture

### Frontend (Flutter App)
- **Framework**: Flutter 3.5.4+
- **Platforms**: Android, iOS, Web, Windows, macOS, Linux
- **State Management**: StatefulWidget with Provider pattern
- **Backend**: Firebase (Firestore, Storage, Authentication)

### Backend Services
- **Firebase**: 
  - Firestore for database
  - Firebase Storage for images
  - Firebase Authentication
  - Firebase Cloud Messaging for notifications

### Machine Learning Services
- **FastAPI**: RESTful API for ML predictions
- **Models**:
  - **Price Prediction**: XGBoost model for device price forecasting
  - **Deal Classification**: Keras neural network for deal quality assessment
  - **Sentiment Analysis**: LSTM model for product review sentiment

## 📁 Project Structure

```
fair_deals/
├── fair_deals_app/          # Flutter mobile application
│   ├── lib/
│   │   ├── main.dart       # App entry point
│   │   ├── models/         # Data models
│   │   └── screens/        # UI screens
│   │       ├── admin/      # Admin screens
│   │       ├── auth/       # Authentication screens
│   │       ├── customer/   # Customer screens
│   │       ├── home/       # Home & product screens
│   │       └── shop/       # Shop owner screens
│   ├── android/            # Android platform files
│   ├── ios/                # iOS platform files
│   └── pubspec.yaml        # Flutter dependencies
│
└── ML/                     # Machine Learning components
    ├── FastApi/            # FastAPI ML service
    │   └── main.py         # ML API endpoints
    ├── Best_Deal/          # Deal classification models
    ├── Phone_Price_Prediction/  # Price prediction models
    ├── Sentiments_Prediction/   # Sentiment analysis models
    └── main.py             # Main ML service entry point
```

## 🛠️ Setup & Installation

### Prerequisites
- Flutter SDK 3.5.4 or higher
- Dart SDK
- Python 3.8+ (for ML services)
- Firebase account
- Android Studio / Xcode (for mobile development)

### Flutter App Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/1010pm/fair_deals.git
   cd fair_deals/fair_deals_app
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
   - Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
   - Download `google-services.json` for Android (place in `android/app/`)
   - Download `GoogleService-Info.plist` for iOS (place in `ios/Runner/`)
   - Update Firebase configuration in `lib/main.dart` (or use environment variables for production)

4. **Run the app**
   ```bash
   flutter run
   ```

### ML Services Setup

1. **Navigate to ML directory**
   ```bash
   cd ML/FastApi
   ```

2. **Install Python dependencies**
   ```bash
   pip install fastapi uvicorn tensorflow xgboost scikit-learn pandas numpy joblib pydantic
   ```

3. **Ensure model files are present**
   - `price_prediction_model_xgb.pkl`
   - `best_deal_improved.keras`
   - `sentiment_lstm.h5`
   - `tokenizer.pkl`

4. **Run the ML API server**
   ```bash
   uvicorn main:app --reload --host 0.0.0.0 --port 8000
   ```

   Or use the main ML service:
   ```bash
   cd ML
   python main.py
   ```

## 🔧 Configuration

### Environment Variables
For production, move sensitive configuration to environment variables:
- Firebase API keys
- ML API endpoints
- Database credentials

### API Endpoints
- **Price Prediction**: `POST /predict_device_price`
- **Deal Classification**: `POST /predict`
- **Sentiment Analysis**: `POST /predict_sentiment/`

## 📱 Usage

### Customer Flow
1. Register/Login as a customer
2. Browse products by category or search
3. View shop details and product information
4. Use price prediction to estimate future prices
5. Save favorites and receive notifications

### Shop Owner Flow
1. Register/Login as a shop owner
2. Complete shop profile and settings
3. Add products with images and details
4. Manage inventory and respond to feedback
5. View analytics and reports

### Admin Flow
1. Login as administrator
2. Manage shops (approve, suspend, delete)
3. Review customer feedback
4. Generate system reports
5. Monitor platform activity

## 🤖 Machine Learning Models

### Price Prediction Model
- **Algorithm**: XGBoost
- **Features**: Brand, CPU, RAM, Storage, Screen Size, Camera, Battery
- **Output**: Predicted prices for 3, 6, 9, and 12 months

### Deal Classification Model
- **Algorithm**: Keras Neural Network
- **Features**: Product type, price, distance, average price
- **Output**: Deal quality (Excellent, Good, Fair, Bad)

### Sentiment Analysis Model
- **Algorithm**: LSTM (Long Short-Term Memory)
- **Input**: Product reviews or feedback text
- **Output**: Sentiment (Positive/Negative) with confidence score

## 🔒 Security

- Password hashing using SHA-256
- Firebase Authentication
- Secure storage for sensitive data
- API key protection (move to environment variables in production)
- Input validation and sanitization

## 📦 Dependencies

### Flutter Dependencies
- `firebase_core`, `firebase_auth`, `cloud_firestore`
- `geolocator`, `google_maps_flutter`
- `http`, `shared_preferences`
- `image_picker`, `flutter_secure_storage`
- And more (see `pubspec.yaml`)

### Python Dependencies
- `fastapi`, `uvicorn`
- `tensorflow`, `keras`
- `xgboost`, `scikit-learn`
- `pandas`, `numpy`, `joblib`

## 🧪 Testing

Run Flutter tests:
```bash
cd fair_deals_app
flutter test
```

## 📝 Notes

- Large CSV datasets and model files are excluded from the repository (see `.gitignore`)
- Firebase credentials should be moved to environment variables for production
- ML models need to be trained separately (training scripts not included)
- The app requires location permissions for shop discovery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 License

This project is private and proprietary.

## 👥 Authors

- **Development Team** - Initial work

## 🙏 Acknowledgments

- Firebase for backend services
- Flutter team for the amazing framework
- TensorFlow and XGBoost communities

---

For more information or support, please contact the development team.
