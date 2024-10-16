import pandas as pd
from sklearn.ensemble import RandomForestRegressor
from sklearn.multioutput import MultiOutputRegressor
from sklearn.preprocessing import LabelEncoder, StandardScaler
from models.model import FertilizerModel

class PredictionService:
    def __init__(self):
        self.model = FertilizerModel()
        self.label_encoder_soil = LabelEncoder()
        self.label_encoder_crop = LabelEncoder()
        self.label_encoder_fertilizer = LabelEncoder()
        self.scaler = StandardScaler()

    def load_and_train_model(self):
        # Load CSV data for training
        df = pd.read_csv('data/Fertilizer Prediction.csv')

        # Encode and preprocess data
        df['Soil Type'] = self.label_encoder_soil.fit_transform(df['Soil Type'])
        df['Crop Type'] = self.label_encoder_crop.fit_transform(df['Crop Type'])
        df['Fertilizer Name'] = self.label_encoder_fertilizer.fit_transform(df['Fertilizer Name'])

        # Split features and targets
        X = df[['Temperature', 'Humidity', 'Moisture', 'Soil Type', 'Crop Type']]
        y_npk = df[['Nitrogen', 'Phosphorous', 'Potassium']]
        y_fertilizer = df['Fertilizer Name']

        # Standardize the features
        X_scaled = self.scaler.fit_transform(X)

        # Train NPK model
        self.npk_model = MultiOutputRegressor(RandomForestRegressor(random_state=42))
        self.npk_model.fit(X_scaled, y_npk)

        # Train Fertilizer model
        self.fertilizer_model = RandomForestRegressor(random_state=42)
        self.fertilizer_model.fit(X_scaled, y_fertilizer)

    def map_mongo_data(self, sensor_data, soil_data):
        temperature = sensor_data.get('temperature', 25)
        humidity = sensor_data.get('humidity', 50)
        moisture = sensor_data.get('soil_moisture', 400)

        soil_type = soil_data.get('soil_type', 'Loamy')
        crop_type = soil_data.get('crop_type', 'Paddy')

        # Encode soil_type and crop_type
        soil_type_encoded = self.label_encoder_soil.transform([soil_type])[0]
        crop_type_encoded = self.label_encoder_crop.transform([crop_type])[0]

        # Return input features for prediction (without NPK values)
        return [[temperature, humidity, moisture, soil_type_encoded, crop_type_encoded]]

    def predict_from_mongo(self):
        # Fetch sensor data from sensor_data collection
        sensor_data = self.model.get_sensor_data()[0]
        
        # Fetch soil data from soil_data collection
        soil_data = self.model.get_soil_data()[0]

        # Log fetched data for verification
        print(f"Sensor Data Fetched: {sensor_data}")
        print(f"Soil Data Fetched: {soil_data}")

        # Preprocess the input for prediction
        input_data = self.map_mongo_data(sensor_data, soil_data)
        input_scaled = self.scaler.transform(input_data)

        # Predict NPK values needed
        npk_prediction = self.npk_model.predict(input_scaled)

        # Predict the recommended fertilizer
        fertilizer_prediction = self.fertilizer_model.predict(input_scaled)
        fertilizer_label = self.label_encoder_fertilizer.inverse_transform([round(fertilizer_prediction[0])])

        return {
            "NPK_values_needed": npk_prediction.tolist(),
            "Fertilizer": fertilizer_label[0]
        }
