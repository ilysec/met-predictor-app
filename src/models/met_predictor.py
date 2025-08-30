"""
MET Prediction Model - Optimized for mobile deployment
"""

import numpy as np
import joblib
import json
import os
from typing import List, Dict, Any

class METPredictor:
    def __init__(self):
        self.model = None
        self.scaler = None
        self.feature_names = None
        self.met_classes = {
            0: "Sedentary",
            1: "Light", 
            2: "Moderate",
            3: "Vigorous"
        }
        
    def train(self, X: np.ndarray, y: np.ndarray, feature_names: List[str]):
        """Train the MET prediction model"""
        from sklearn.ensemble import RandomForestClassifier
        from sklearn.preprocessing import StandardScaler
        from sklearn.model_selection import train_test_split
        from sklearn.metrics import classification_report, accuracy_score
        
        # Split data
        X_train, X_test, y_train, y_test = train_test_split(
            X, y, test_size=0.2, random_state=42, stratify=y
        )
        
        # Scale features
        self.scaler = StandardScaler()
        X_train_scaled = self.scaler.fit_transform(X_train)
        X_test_scaled = self.scaler.transform(X_test)
        
        # Train model (optimized for mobile)
        self.model = RandomForestClassifier(
            n_estimators=50,  # Smaller for mobile
            max_depth=10,
            random_state=42,
            n_jobs=-1
        )
        
        self.model.fit(X_train_scaled, y_train)
        self.feature_names = feature_names
        
        # Evaluate
        y_pred = self.model.predict(X_test_scaled)
        accuracy = accuracy_score(y_test, y_pred)
        
        print(f"Model Accuracy: {accuracy:.3f}")
        print("\nClassification Report:")
        
        # Get unique classes in test set
        unique_classes = sorted(np.unique(np.concatenate([y_test, y_pred])))
        target_names = [self.met_classes[i] for i in unique_classes]
        
        print(classification_report(y_test, y_pred, 
                                  labels=unique_classes,
                                  target_names=target_names))
        
        return accuracy
    
    def predict(self, features: List[float]) -> Dict[str, Any]:
        """Predict MET class from features"""
        if self.model is None or self.scaler is None:
            raise ValueError("Model not trained or loaded")
        
        # Reshape and scale features
        features_array = np.array(features).reshape(1, -1)
        features_scaled = self.scaler.transform(features_array)
        
        # Predict
        prediction = self.model.predict(features_scaled)[0]
        probabilities = self.model.predict_proba(features_scaled)[0]
        
        return {
            'predicted_class': int(prediction),
            'class_name': self.met_classes[prediction],
            'probabilities': probabilities.tolist(),
            'confidence': float(np.max(probabilities))
        }
    
    def save_model(self, model_dir: str):
        """Save model for mobile deployment"""
        os.makedirs(model_dir, exist_ok=True)
        
        # Save model and scaler
        joblib.dump(self.model, os.path.join(model_dir, 'met_model.pkl'))
        joblib.dump(self.scaler, os.path.join(model_dir, 'scaler.pkl'))
        
        # Save metadata
        metadata = {
            'feature_names': self.feature_names,
            'met_classes': self.met_classes,
            'model_type': 'RandomForestClassifier',
            'n_features': len(self.feature_names)
        }
        
        with open(os.path.join(model_dir, 'model_metadata.json'), 'w') as f:
            json.dump(metadata, f, indent=2)
        
        print(f"Model saved to {model_dir}")
    
    def load_model(self, model_dir: str):
        """Load trained model"""
        self.model = joblib.load(os.path.join(model_dir, 'met_model.pkl'))
        self.scaler = joblib.load(os.path.join(model_dir, 'scaler.pkl'))
        
        with open(os.path.join(model_dir, 'model_metadata.json'), 'r') as f:
            metadata = json.load(f)
        
        self.feature_names = metadata['feature_names']
        self.met_classes = {int(k): v for k, v in metadata['met_classes'].items()}
        
        print(f"Model loaded from {model_dir}")
    
    def export_for_mobile(self, output_dir: str):
        """Export model in format suitable for mobile deployment"""
        os.makedirs(output_dir, exist_ok=True)
        
        # Export model parameters for CoreML conversion
        if hasattr(self.model, 'estimators_'):
            # Export tree structure (simplified for demo)
            tree_params = {
                'n_estimators': self.model.n_estimators,
                'max_depth': self.model.max_depth,
                'feature_importances': self.model.feature_importances_.tolist(),
                'classes': self.model.classes_.tolist()
            }
            
            with open(os.path.join(output_dir, 'tree_params.json'), 'w') as f:
                json.dump(tree_params, f, indent=2)
        
        # Export scaler parameters
        scaler_params = {
            'mean': self.scaler.mean_.tolist(),
            'scale': self.scaler.scale_.tolist()
        }
        
        with open(os.path.join(output_dir, 'scaler_params.json'), 'w') as f:
            json.dump(scaler_params, f, indent=2)
        
        print(f"Mobile-ready model exported to {output_dir}")
