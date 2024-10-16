from pymongo import MongoClient
from config import Config

class FertilizerModel:
    def __init__(self):
        self.client = MongoClient(Config.MONGO_URI)
        self.db = self.client.get_database('smart_agriculture') 

    def get_sensor_data(self):
        # Fetch the most recent sensor data from sensor_data collection
        return list(self.db.sensor_data.find().sort('timestamp', -1).limit(1))

    def get_soil_data(self):
        # Fetch the most recent soil data from soil_data collection
        return list(self.db.soil_data.find().sort('timestamp', -1).limit(1))

    def insert_prediction(self, prediction):
        # Insert a prediction into MongoDB
        self.db.predictions.insert_one(prediction)
