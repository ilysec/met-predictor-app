# MET Predictor App

A real-time iOS app that predicts Metabolic Equivalent of Task (MET) values from smartphone accelerometer data.

## Overview

This project builds an iOS app that continuously predicts a user's current MET class from smartphone accelerometer data and displays cumulative time spent in each activity category:

- **Sedentary** (< 1.5 METs): sitting, lying, minimal movement
- **Light** (1.5–3 METs): slow walking, light household tasks  
- **Moderate** (3–6 METs): brisk walking, casual cycling
- **Vigorous** (> 6 METs): running, intense exercise

## Project Structure

```
met-predictor-app/
├── data/                          # Training datasets
├── notebooks/                     # Jupyter notebooks for model development
├── src/
│   ├── data_processing/          # Data preprocessing scripts
│   ├── feature_extraction/       # Feature engineering
│   ├── models/                   # ML model training/evaluation
│   └── utils/                    # Utility functions
├── ios-app/                      # iOS application source code
├── models/                       # Trained model files
├── reports/                      # Technical documentation
└── scripts/                      # Training and evaluation scripts
```

## Development Phases

### Phase 1: Data & Model Development (Days 1-2)
- Download and preprocess public datasets (UCI HAR, WISDM, PAMAP2)
- Extract time/frequency domain features from accelerometer data
- Train classification model for MET prediction
- Validate model performance

### Phase 2: iOS App Development (Days 2-3)
- Create SwiftUI interface with real-time MET display
- Implement Core Motion for accelerometer data collection
- Integrate trained model using Core ML
- Add time tracking and cumulative statistics

### Phase 3: Testing & Documentation (Day 4)
- End-to-end testing on iPhone
- Generate technical report
- Create demo video
- Prepare final deliverables

## Getting Started

1. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

2. Run data preparation notebook:
   ```bash
   jupyter notebook notebooks/01_data_preparation.ipynb
   ```

3. Train the model:
   ```bash
   python scripts/train_model.py
   ```

4. Open iOS project in Xcode and build for device testing.

## Datasets Used

- UCI Human Activity Recognition Using Smartphones
- WISDM Activity Recognition Dataset  
- PAMAP2 Physical Activity Monitoring Dataset
- Custom collected data for validation

## Technical Approach

- **Features**: Time and frequency domain features from 3-axis accelerometer
- **Model**: Random Forest/SVM for robust real-time classification
- **MET Mapping**: Based on Compendium of Physical Activities
- **Real-time Processing**: 2.56s sliding windows with 50% overlap

## License

MIT License - see LICENSE file for details.
