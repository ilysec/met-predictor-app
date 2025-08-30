"""
Feature extraction optimized for mobile deployment
"""

import numpy as np
from typing import List, Dict, Any

class METFeatureExtractor:
    def __init__(self, window_size: int = 50, sampling_rate: int = 20):
        self.window_size = window_size
        self.sampling_rate = sampling_rate
        
    def extract_features(self, accel_data: Dict[str, List[float]]) -> List[float]:
        """
        Extract time-domain features optimized for mobile inference
        
        Args:
            accel_data: Dict with 'x', 'y', 'z' acceleration data
            
        Returns:
            Feature vector (16 features)
        """
        x = np.array(accel_data['x'])
        y = np.array(accel_data['y'])
        z = np.array(accel_data['z'])
        
        # Calculate magnitude
        magnitude = np.sqrt(x**2 + y**2 + z**2)
        
        features = []
        
        # Mean values (4 features)
        features.extend([
            np.mean(x), np.mean(y), np.mean(z), np.mean(magnitude)
        ])
        
        # Standard deviation (4 features)
        features.extend([
            np.std(x), np.std(y), np.std(z), np.std(magnitude)
        ])
        
        # Min/Max magnitude (2 features)
        features.extend([np.min(magnitude), np.max(magnitude)])
        
        # RMS values (3 features)
        features.extend([
            np.sqrt(np.mean(x**2)),
            np.sqrt(np.mean(y**2)),
            np.sqrt(np.mean(z**2))
        ])
        
        # Zero crossing rate for x-axis (1 feature)
        mean_x = np.mean(x)
        zero_crossings = np.sum(np.diff(np.sign(x - mean_x)) != 0)
        features.append(zero_crossings)
        
        # Percentiles of magnitude (2 features)
        features.extend([
            np.percentile(magnitude, 25),
            np.percentile(magnitude, 75)
        ])
        
        return features
    
    def get_feature_names(self) -> List[str]:
        """Return feature names for model training"""
        return [
            'mean_x', 'mean_y', 'mean_z', 'mean_magnitude',
            'std_x', 'std_y', 'std_z', 'std_magnitude',
            'min_magnitude', 'max_magnitude',
            'rms_x', 'rms_y', 'rms_z',
            'zero_crossings_x',
            'magnitude_p25', 'magnitude_p75'
        ]
