import os

class Config:
    # MongoDB configuration
    
    MONGO_URI = os.getenv("MONGO_URI", "mongodb+srv://jijinjebanesh:K12Sc7TQqEwXE5S5@fertioptimizer.gjsww.mongodb.net/?retryWrites=true&w=majority&appName=FertiOptimizer")
