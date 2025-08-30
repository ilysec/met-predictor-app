#!/usr/bin/env python3
"""
Complete training pipeline for MET prediction
Run this script to train and export the model
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from src.data_processing.wisdm_processor import WISDMDataProcessor
from src.feature_extraction.feature_extractor import METFeatureExtractor
from src.models.met_predictor import METPredictor
import pandas as pd
import numpy as np

def create_features_from_dataframe(df, extractor, window_size=50):
    """Extract features from dataframe in sliding windows"""
    features = []
    labels = []
    
    for user in df['user'].unique():
        user_data = df[df['user'] == user]
        
        for activity in user_data['activity'].unique():
            activity_data = user_data[user_data['activity'] == activity]
            
            # Create sliding windows
            for i in range(0, len(activity_data) - window_size + 1, window_size//2):
                window = activity_data.iloc[i:i+window_size]
                
                if len(window) == window_size:
                    accel_data = {
                        'x': window['x'].values.tolist(),
                        'y': window['y'].values.tolist(),
                        'z': window['z'].values.tolist()
                    }
                    
                    feature_vector = extractor.extract_features(accel_data)
                    features.append(feature_vector)
                    labels.append(window['met_class'].iloc[0])  # Use first label in window
    
    return np.array(features), np.array(labels)

def main():
    """Main training pipeline"""
    print("Starting MET prediction training pipeline...")
    
    # 1. Process data
    print("\n1. Processing data...")
    processor = WISDMDataProcessor()
    
    try:
        processor.download_wisdm_dataset()
    except Exception as e:
        print(f"Dataset download failed: {e}")
        print("Using synthetic data for demonstration")
    
    df = processor.load_and_process_data()
    
    # 2. Extract features
    print("\n2. Extracting features...")
    extractor = METFeatureExtractor(window_size=50)
    X, y = create_features_from_dataframe(df, extractor)
    
    print(f"Feature matrix shape: {X.shape}")
    print(f"Labels shape: {y.shape}")
    print(f"Classes distribution: {np.bincount(y)}")
    
    # 3. Train model
    print("\n3. Training model...")
    predictor = METPredictor()
    accuracy = predictor.train(X, y, extractor.get_feature_names())
    
    # 4. Save model
    print("\n4. Saving model...")
    model_dir = "models/trained"
    predictor.save_model(model_dir)
    
    # 5. Export for mobile
    print("\n5. Exporting for mobile deployment...")
    mobile_dir = "models/mobile"
    predictor.export_for_mobile(mobile_dir)
    
    print(f"\n✅ Training complete!")
    print(f"Model accuracy: {accuracy:.3f}")
    print(f"Model saved to: {model_dir}")
    print(f"Mobile export saved to: {mobile_dir}")
    
    # Test prediction
    print("\n6. Testing prediction...")
    test_features = X[0]  # Use first sample
    result = predictor.predict(test_features.tolist())
    print(f"Test prediction: {result}")

if __name__ == "__main__":
    main()
