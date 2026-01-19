import requests

url = "http://127.0.0.1:8000/predict/"

test_samples = [
    {"product": "iPhone 15", "price": 140, "distance": 15},
    {"product": "iPhone 15", "price": 120, "distance": 10},  
    {"product": "iPhone 15", "price": 145, "distance": 10},
    {"product": "iPhone 15", "price": 1400, "distance": 10},  
    {"product": "Samsung Galaxy S23", "price": 1000, "distance": 20},  
    {"product": "MacBook Air", "price": 800, "distance": 25},  
    {"product": "GoPro Camera", "price": 400, "distance": 15},  
    {"product": "Apple Watch", "price": 200, "distance": 10},   
    {"product": "Bose Headphones", "price": 300, "distance": 30},  
    {"product": "Bose Headphones", "price": 352, "distance": 30},
    {"product": "Bose Headphones", "price": 300, "distance": 10},
    {"product": "iPhone 15", "price": 115, "distance": 10}
]

for sample in test_samples:
    response = requests.post(url, json=sample)
    print(response.json())
