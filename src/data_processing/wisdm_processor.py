"""
MET Prediction Data Processing
Fast pipeline for WISDM dataset with MET labeling
"""

import pandas as pd
import numpy as np
import requests
import zipfile
import os
from urllib.parse import urlparse

class WISDMDataProcessor:
    def __init__(self, data_dir="data"):
        self.data_dir = data_dir
        self.raw_data_path = os.path.join(data_dir, "raw")
        self.processed_data_path = os.path.join(data_dir, "processed")
        
        # Create directories
        os.makedirs(self.raw_data_path, exist_ok=True)
        os.makedirs(self.processed_data_path, exist_ok=True)
        
        # Activity to MET mapping (from Compendium of Physical Activities)
        self.activity_met_mapping = {
            'Walking': 3.0,      # Moderate (Class 2)
            'Jogging': 7.0,      # Vigorous (Class 3)
            'Running': 8.0,      # Vigorous (Class 3)
            'Upstairs': 4.0,     # Moderate (Class 2)
            'Downstairs': 3.5,   # Moderate (Class 2)
            'Sitting': 1.0,      # Sedentary (Class 0)
            'Standing': 1.2,     # Light (Class 1)
            'SlowWalk': 2.5      # Light (Class 1)
        }
    
    def download_wisdm_dataset(self):
        """Download WISDM dataset"""
        # Use alternative WISDM dataset URL
        url = "https://archive.ics.uci.edu/ml/machine-learning-databases/00507/wisdm-dataset.zip"
        
        zip_path = os.path.join(self.raw_data_path, "wisdm-dataset.zip")
        
        if not os.path.exists(zip_path):
            print("Downloading WISDM dataset...")
            response = requests.get(url)
            with open(zip_path, 'wb') as f:
                f.write(response.content)
            print("Download complete")
        
        # Extract
        with zipfile.ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(self.raw_data_path)
        
        return True
    
    def load_and_process_data(self):
        """Load and process WISDM data with MET labels"""
        # Look for WISDM data files
        data_file = None
        for root, dirs, files in os.walk(self.raw_data_path):
            for file in files:
                if 'WISDM' in file and file.endswith('.txt'):
                    data_file = os.path.join(root, file)
                    break
        
        if data_file is None:
            # Create synthetic data for quick testing
            print("Creating synthetic dataset for quick testing...")
            return self.create_synthetic_data()
        
        # Load WISDM data
        print(f"Loading data from {data_file}")
        
        # WISDM format: user,activity,timestamp,x-axis,y-axis,z-axis
        try:
            df = pd.read_csv(data_file, header=None, 
                           names=['user', 'activity', 'timestamp', 'x', 'y', 'z'])
        except:
            # Alternative format handling
            with open(data_file, 'r') as f:
                lines = f.readlines()
            
            data = []
            for line in lines:
                parts = line.strip().rstrip(';').split(',')
                if len(parts) >= 6:
                    data.append(parts[:6])
            
            df = pd.DataFrame(data, columns=['user', 'activity', 'timestamp', 'x', 'y', 'z'])
        
        # Clean data
        df = df.dropna()
        df['x'] = pd.to_numeric(df['x'], errors='coerce')
        df['y'] = pd.to_numeric(df['y'], errors='coerce')
        df['z'] = pd.to_numeric(df['z'], errors='coerce')
        df = df.dropna()
        
        # Add MET values and classes
        df['met_value'] = df['activity'].map(self.activity_met_mapping)
        df['met_class'] = df['met_value'].apply(self.get_met_class)
        
        # Save processed data
        processed_file = os.path.join(self.processed_data_path, "wisdm_with_met.csv")
        df.to_csv(processed_file, index=False)
        
        print(f"Processed data saved to {processed_file}")
        print(f"Dataset shape: {df.shape}")
        print(f"Activities: {df['activity'].unique()}")
        print(f"MET classes distribution:\n{df['met_class'].value_counts()}")
        
        return df
    
    def create_synthetic_data(self):
        """Create synthetic accelerometer data for quick testing"""
        np.random.seed(42)
        
        activities = ['Sitting', 'Standing', 'SlowWalk', 'Walking', 'Jogging', 'Upstairs', 'Downstairs']
        data = []
        
        for activity in activities:
            for user in range(1, 11):  # 10 users
                for session in range(100):  # 100 sessions per user per activity
                    # Generate realistic accelerometer patterns
                    if activity == 'Sitting':
                        x = np.random.normal(0, 0.5)
                        y = np.random.normal(0, 0.5)
                        z = np.random.normal(9.8, 0.5)
                    elif activity == 'Standing':
                        x = np.random.normal(0, 1.0)
                        y = np.random.normal(0, 1.0)
                        z = np.random.normal(9.8, 1.0)
                    elif activity == 'SlowWalk':
                        x = np.random.normal(0, 2.0)
                        y = np.random.normal(0, 2.0)
                        z = np.random.normal(9.8, 2.0)
                    elif activity == 'Walking':
                        x = np.random.normal(0, 3.0)
                        y = np.random.normal(0, 3.0)
                        z = np.random.normal(9.8, 3.0)
                    elif activity == 'Jogging':
                        x = np.random.normal(0, 6.0)
                        y = np.random.normal(0, 6.0)
                        z = np.random.normal(9.8, 6.0)
                    elif activity in ['Upstairs', 'Downstairs']:
                        x = np.random.normal(0, 4.0)
                        y = np.random.normal(0, 4.0)
                        z = np.random.normal(9.8, 4.0)
                    
                    data.append([user, activity, session, x, y, z])
        
        df = pd.DataFrame(data, columns=['user', 'activity', 'timestamp', 'x', 'y', 'z'])
        
        # Add MET values and classes
        df['met_value'] = df['activity'].map(self.activity_met_mapping)
        df['met_class'] = df['met_value'].apply(self.get_met_class)
        
        # Save
        processed_file = os.path.join(self.processed_data_path, "synthetic_met_data.csv")
        df.to_csv(processed_file, index=False)
        
        print(f"Synthetic dataset created: {df.shape}")
        print(f"All classes: {sorted(df['met_class'].unique())}")
        print(f"Class distribution: {df['met_class'].value_counts().sort_index().to_dict()}")
        return df
    
    def get_met_class(self, met_value):
        """Convert MET value to class"""
        if met_value < 1.5:
            return 0  # Sedentary
        elif met_value < 3.0:
            return 1  # Light
        elif met_value < 6.0:
            return 2  # Moderate
        else:
            return 3  # Vigorous

if __name__ == "__main__":
    processor = WISDMDataProcessor()
    
    # Try to download dataset, fallback to synthetic
    try:
        processor.download_wisdm_dataset()
    except:
        print("Download failed, will use synthetic data")
    
    # Process data
    df = processor.load_and_process_data()
    print("Data processing complete!")
