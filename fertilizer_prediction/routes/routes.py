from flask import Blueprint, jsonify
from services.prediction_service import PredictionService

routes = Blueprint('routes', __name__)

# Initialize PredictionService
prediction_service = PredictionService()

@routes.route('/train', methods=['GET'])
def train_model():
    # Train the models
    prediction_service.load_and_train_model()
    return jsonify({"message": "Model trained successfully!"})

@routes.route('/predict', methods=['GET'])
def predict_from_mongo():
    # Predict based on MongoDB data
    result = prediction_service.predict_from_mongo()
    return jsonify(result)
