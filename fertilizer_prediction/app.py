from flask import Flask, request, jsonify
from pymongo import MongoClient
from datetime import datetime
import uuid
import threading
from config import Config
from routes.routes import routes  # Assuming you still want to keep routes in a separate module
from services.prediction_service import PredictionService  # Assuming this is still needed
import time
from bson import ObjectId

app = Flask(__name__)

# Load configuration
app.config.from_object(Config)

# Register routes
app.register_blueprint(routes)

# Connect to MongoDB
client = MongoClient(Config.MONGO_URI)
db = client['smart_agriculture']
sensor_collection = db['sensor_data']
irrigation_collection = db['irrigation_control']

@app.route('/data', methods=['POST'])
def receive_data():
    try:
        # Get JSON data from the POST request
        data = request.json

        # Create a document for the sensor data
        sensor_data = {
            "_id": str(uuid.uuid4()),  # Generate a unique ID
            "sensor_id": data.get("sensor_id", "unknown_sensor"),  # Default sensor ID if not provided
            "field_id": data.get("field_id", "unknown_field"),  # Default field ID if not provided
            "soil_moisture": data.get("moisture"),
            "temperature": data.get("temperature"),
            "humidity": data.get("humidity"),
            "timestamp": datetime.utcnow()  # Use the current UTC time as the timestamp
        }

        # Insert the document into the collection
        sensor_collection.insert_one(sensor_data)

        return jsonify({"message": "Data received and inserted", "data": sensor_data}), 200

    except Exception as e:
        return jsonify({"error": str(e)}), 500

# Function to fetch the latest motor status
def fetch_motor_status():
    while True:
        # Fetch the latest motor status every 5 seconds (adjust as needed)
        motor_data = irrigation_collection.find_one({}, sort=[('timestamp', -1)])  # Fetch the latest record
        if motor_data:
            status = motor_data.get('motor_status', 'OFF')  # Default to OFF if not found
        else:
            print("Motor status not found. Defaulting to OFF.")
        
        # Sleep for a while before the next check
        time.sleep(5)

# Endpoint for ESP12E to fetch motor status
@app.route('/motor_status', methods=['GET'])
def motor_status():
    motor_data = irrigation_collection.find_one({}, sort=[('timestamp', -1)])  # Fetch the latest record
    if motor_data:
        return jsonify({"motor_status": motor_data.get('motor_status', 'OFF')})
    return jsonify({"motor_status": 'OFF'})

@app.route('/motor', methods=['POST'])
def update_motor_status():
    try:
        data = request.json
        motor_status = data.get("motor_status")
        control = data.get("control", "schedule")  # Default to "schedule"

        if motor_status not in ["ON", "OFF"]:
            return jsonify({"error": "Invalid motor status"}), 400

        # Prepare the motor data document
        motor_data = {
            "motor_id": "motor001",
            "field_id": "field001",
            "motor_status": motor_status,
            "control": control,
            "timestamp": datetime.utcnow().isoformat()  # Use the current UTC time as the timestamp
        }

        # Insert the motor status document into the collection
        result = irrigation_collection.insert_one(motor_data)

        # Convert ObjectId to a string before returning in the response
        motor_data["_id"] = str(result.inserted_id)

        return jsonify({"message": "Motor status inserted", "data": motor_data}), 201

    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    # Start the motor control thread
    motor_thread = threading.Thread(target=fetch_motor_status)
    motor_thread.daemon = True  # Ensure the thread exits when the main program exits
    motor_thread.start()

    # Bind to all network interfaces and set the port to 6000
    app.run(host='0.0.0.0', port=6000, debug=True)
