//
//  ContentView.swift
//  METPredictor
//
//  Created by Ilyas Seckin on 29.08.2025.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    @StateObject private var accelerometerManager = AccelerometerManager()
    @StateObject private var timeTracker = TimeTracker()
    @State private var showingStatistics = false
    @State private var showingSettings = false
    @State private var selectedPlotType: PlotType = .magnitude
    
    enum PlotType: String, CaseIterable {
        case magnitude = "Magnitude"
        case x = "X-Axis"
        case y = "Y-Axis"
        case z = "Z-Axis"
        case all = "All Axes"
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Header
                    VStack {
                        Text("MET Predictor")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Text("Real-time Activity Classification")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top)
                
                // Current Activity
                VStack(spacing: 10) {
                    Text("Current Activity")
                        .font(.headline)
                    
                    RoundedRectangle(cornerRadius: 20)
                        .fill(colorForMETClass(accelerometerManager.currentMETClass))
                        .frame(height: 100)
                        .overlay(
                            VStack {
                                Text(nameForMETClass(accelerometerManager.currentMETClass))
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Text("Confidence: \(Int(accelerometerManager.confidence * 100))%")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        )
                }
                .padding(.horizontal)
                
                // Daily Time Summary
                VStack(spacing: 15) {
                    Text("Today's Activity Time")
                        .font(.headline)
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 15) {
                        ForEach(0..<4, id: \.self) { metClass in
                            METClassCard(
                                metClass: metClass,
                                time: timeTracker.dailyTimes[metClass] ?? 0,
                                isActive: accelerometerManager.currentMETClass == metClass
                            )
                        }
                    }
                }
                .padding(.horizontal)
                
                // Today's Activity Graph
                ActivityGraphView(hourlyActivity: timeTracker.hourlyActivity)
                    .padding(.horizontal)
                
                // Enhanced Live Accelerometer Plot with Controls
                VStack(alignment: .leading, spacing: 15) {
                    HStack {
                        Text("Live Accelerometer Data")
                            .font(.headline)
                        
                        Spacer()
                        
                        // Simple data source indicator
                        HStack(spacing: 6) {
                            Circle()
                                .fill(accelerometerManager.useDummyData ? Color.orange : Color.green)
                                .frame(width: 8, height: 8)
                            Text(accelerometerManager.useDummyData ? "Demo Mode" : "Live Mode")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    
                    // Plot type selector
                    Picker("Plot Type", selection: $selectedPlotType) {
                        ForEach(PlotType.allCases, id: \.self) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    // Enhanced plot view
                    EnhancedAccelerometerPlotView(
                        accelerometerManager: accelerometerManager,
                        plotType: selectedPlotType
                    )
                }
                .padding(.horizontal)
                
                // Quick Insights
                VStack(alignment: .leading, spacing: 8) {
                    Text("Today's Insights")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(timeTracker.getActivityInsights())
                        .font(.caption)
                        .padding()
                        .background(Color(.systemBlue).opacity(0.1))
                        .cornerRadius(10)
                        .padding(.horizontal)
                }
                
                Spacer()
                
                // Controls
                VStack(spacing: 15) {
                    // Statistics Button
                    Button(action: {
                        showingStatistics = true
                    }) {
                        HStack {
                            Image(systemName: "chart.bar.fill")
                            Text("View Statistics")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.purple)
                        .cornerRadius(10)
                    }
                    
                    // Developer Settings Button
                    Button(action: {
                        showingSettings = true
                    }) {
                        HStack {
                            Image(systemName: "gearshape.2.fill")
                            Text("Developer Settings")
                        }
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
            }
            .padding(.bottom, 20)
        }
    }
        .onAppear {
            // Ensure both components start in live mode and are synchronized
            accelerometerManager.useDummyData = false
            if timeTracker.isDummyMode {
                timeTracker.disableDummyMode()
            }
            
            // Auto-start tracking
            accelerometerManager.startTracking()
        }
        .onChange(of: accelerometerManager.currentMETClass) { _, newClass in
            timeTracker.updateCurrentActivity(metClass: newClass)
        }
        .sheet(isPresented: $showingStatistics) {
            StatisticsView(timeTracker: timeTracker)
        }
        .sheet(isPresented: $showingSettings) {
            DeveloperSettingsView(accelerometerManager: accelerometerManager, timeTracker: timeTracker)
        }
    }
}

struct METClassCard: View {
    let metClass: Int
    let time: TimeInterval
    let isActive: Bool
    
    var body: some View {
        VStack(spacing: 8) {
            Text(nameForMETClass(metClass))
                .font(.headline)
                .foregroundColor(isActive ? .white : .primary)
            
            Text(formatTime(time))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(isActive ? .white : .primary)
            
            Text("today")
                .font(.caption)
                .foregroundColor(isActive ? .white.opacity(0.8) : .secondary)
        }
        .frame(height: 80)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 15)
                .fill(isActive ? colorForMETClass(metClass) : Color(.systemGray6))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 15)
                .stroke(isActive ? Color.clear : colorForMETClass(metClass), lineWidth: 2)
        )
    }
}

// Helper functions
func nameForMETClass(_ metClass: Int) -> String {
    switch metClass {
    case 0: return "Sedentary"
    case 1: return "Light Activity"
    case 2: return "Moderate Activity"
    case 3: return "Vigorous Activity"
    default: return "Unknown"
    }
}

func colorForMETClass(_ metClass: Int) -> Color {
    switch metClass {
    case 0: return .blue
    case 1: return .green
    case 2: return .orange
    case 3: return .red
    default: return .gray
    }
}

func formatTime(_ time: TimeInterval) -> String {
    let hours = Int(time) / 3600
    let minutes = (Int(time) % 3600) / 60
    
    if hours > 0 {
        return "\(hours)h \(minutes)m"
    } else {
        return "\(minutes)m"
    }
}

#Preview {
    ContentView()
}

// MARK: - Enhanced Plotting Components

struct EnhancedAccelerometerPlotView: View {
    @ObservedObject var accelerometerManager: AccelerometerManager
    let plotType: ContentView.PlotType
    
    var body: some View {
        VStack(spacing: 12) {
            // Real-time values display
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("X: \(accelerometerManager.currentAcceleration.x, specifier: "%.3f")")
                        .foregroundColor(.red)
                    Text("Y: \(accelerometerManager.currentAcceleration.y, specifier: "%.3f")")
                        .foregroundColor(.green)
                    Text("Z: \(accelerometerManager.currentAcceleration.z, specifier: "%.3f")")
                        .foregroundColor(.blue)
                }
                .font(.system(.caption, design: .monospaced))
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Magnitude: \(accelerometerManager.currentMagnitude, specifier: "%.3f")")
                    Text("Activity: \(Int(accelerometerManager.activityLevel * 100))%")
                    Text("Status: \(accelerometerManager.isMoving ? "Moving" : "Still")")
                        .foregroundColor(accelerometerManager.isMoving ? .green : .orange)
                }
                .font(.system(.caption, design: .monospaced))
            }
            
            // Plot area with proper scaling
            ZStack {
                // Plot based on selected type
                switch plotType {
                case .magnitude:
                    AccelerometerDataPlot(
                        data: accelerometerManager.recentMagnitudes,
                        color: .blue,
                        label: "Magnitude",
                        threshold: 1.2
                    )
                case .x:
                    AccelerometerDataPlot(
                        data: accelerometerManager.recentAccelerationX,
                        color: .red,
                        label: "X-Axis",
                        threshold: nil
                    )
                case .y:
                    AccelerometerDataPlot(
                        data: accelerometerManager.recentAccelerationY,
                        color: .green,
                        label: "Y-Axis",
                        threshold: nil
                    )
                case .z:
                    AccelerometerDataPlot(
                        data: accelerometerManager.recentAccelerationZ,
                        color: .blue,
                        label: "Z-Axis",
                        threshold: nil
                    )
                case .all:
                    MultiAxisPlot(accelerometerManager: accelerometerManager)
                }
            }
            .frame(height: 120)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            
            // Data source indicator
            HStack {
                Circle()
                    .fill(accelerometerManager.useDummyData ? Color.orange : Color.green)
                    .frame(width: 8, height: 8)
                
                Text(accelerometerManager.useDummyData ? "Displaying realistic dummy data" : "Live sensor data")
                    .font(.caption2)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                if accelerometerManager.useDummyData {
                    Text("Cycles through all activity levels")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
}

struct AccelerometerDataPlot: View {
    let data: [Double]
    let color: Color
    let label: String
    let threshold: Double?
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Better scaling - use data range with some padding
            let dataRange = getDataRange()
            let minValue = dataRange.min
            let maxValue = dataRange.max
            let range = maxValue - minValue
            
            ZStack {
                // Threshold line if provided
                if let threshold = threshold {
                    Path { path in
                        let y = height - CGFloat((threshold - minValue) / range) * height
                        path.move(to: CGPoint(x: 0, y: y))
                        path.addLine(to: CGPoint(x: width, y: y))
                    }
                    .stroke(Color.red.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [5]))
                }
                
                // Data line
                if data.count > 1 {
                    Path { path in
                        let stepX = width / CGFloat(data.count - 1)
                        
                        for (index, value) in data.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - CGFloat((value - minValue) / range) * height
                            
                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(color, lineWidth: 2)
                }
                
                // Scale labels
                VStack {
                    HStack {
                        Text("\(maxValue, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(label)
                            .font(.caption2)
                            .fontWeight(.medium)
                    }
                    Spacer()
                    HStack {
                        Text("\(minValue, specifier: "%.2f")")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
                .padding(4)
            }
        }
    }
    
    private func getDataRange() -> (min: Double, max: Double) {
        guard !data.isEmpty else { return (min: -2.0, max: 2.0) }
        
        let minVal = data.min() ?? -2.0
        let maxVal = data.max() ?? 2.0
        
        // Add some padding to the range
        let padding = max(0.1, (maxVal - minVal) * 0.1)
        
        return (min: minVal - padding, max: maxVal + padding)
    }
}

struct MultiAxisPlot: View {
    @ObservedObject var accelerometerManager: AccelerometerManager
    
    var body: some View {
        GeometryReader { geometry in
            let width = geometry.size.width
            let height = geometry.size.height
            
            // Get combined range for all axes
            let allData = accelerometerManager.recentAccelerationX + 
                         accelerometerManager.recentAccelerationY + 
                         accelerometerManager.recentAccelerationZ
            
            guard !allData.isEmpty else {
                return AnyView(Text("No data").foregroundColor(.secondary))
            }
            
            let minValue = allData.min()! - 0.5
            let maxValue = allData.max()! + 0.5
            let range = maxValue - minValue
            
            return AnyView(
                ZStack {
                    // X-axis
                    if accelerometerManager.recentAccelerationX.count > 1 {
                        plotLine(
                            data: accelerometerManager.recentAccelerationX,
                            width: width,
                            height: height,
                            minValue: minValue,
                            range: range,
                            color: .red
                        )
                    }
                    
                    // Y-axis
                    if accelerometerManager.recentAccelerationY.count > 1 {
                        plotLine(
                            data: accelerometerManager.recentAccelerationY,
                            width: width,
                            height: height,
                            minValue: minValue,
                            range: range,
                            color: .green
                        )
                    }
                    
                    // Z-axis
                    if accelerometerManager.recentAccelerationZ.count > 1 {
                        plotLine(
                            data: accelerometerManager.recentAccelerationZ,
                            width: width,
                            height: height,
                            minValue: minValue,
                            range: range,
                            color: .blue
                        )
                    }
                    
                    // Legend and scale
                    VStack {
                        HStack {
                            HStack(spacing: 2) {
                                Circle().fill(Color.red).frame(width: 6, height: 6)
                                Text("X")
                                Circle().fill(Color.green).frame(width: 6, height: 6)
                                Text("Y")
                                Circle().fill(Color.blue).frame(width: 6, height: 6)
                                Text("Z")
                            }
                            .font(.caption2)
                            
                            Spacer()
                            
                            Text("\(maxValue, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        HStack {
                            Spacer()
                            Text("\(minValue, specifier: "%.1f")")
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(4)
                }
            )
        }
    }
    
    private func plotLine(data: [Double], width: CGFloat, height: CGFloat, minValue: Double, range: Double, color: Color) -> some View {
        Path { path in
            let stepX = width / CGFloat(data.count - 1)
            
            for (index, value) in data.enumerated() {
                let x = CGFloat(index) * stepX
                let y = height - CGFloat((value - minValue) / range) * height
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    path.addLine(to: CGPoint(x: x, y: y))
                }
            }
        }
        .stroke(color, lineWidth: 1.5)
    }
}

// Developer Settings View
struct DeveloperSettingsView: View {
    @ObservedObject var accelerometerManager: AccelerometerManager
    @ObservedObject var timeTracker: TimeTracker
    @Environment(\.dismiss) private var dismiss
    @State private var showingModelSelection = false
    
    var body: some View {
        NavigationView {
            List {
                Section {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Demo Mode")
                                .font(.body)
                            Text("Use realistic dummy data for demonstration")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Toggle("", isOn: Binding(
                            get: { accelerometerManager.useDummyData },
                            set: { newValue in
                                // Synchronize both components
                                accelerometerManager.useDummyData = newValue
                                UserDefaults.standard.set(newValue, forKey: "AccelerometerUseDummyData")
                                
                                if newValue {
                                    timeTracker.enableDummyMode()
                                } else {
                                    timeTracker.disableDummyMode()
                                }
                            }
                        ))
                        .toggleStyle(SwitchToggleStyle())
                    }
                    .padding(.vertical, 4)
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Detection Model")
                                .font(.body)
                            Text(accelerometerManager.currentModel.rawValue)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                        
                        Button("Change") {
                            showingModelSelection = true
                        }
                        .foregroundColor(.accentColor)
                    }
                    .padding(.vertical, 4)
                } header: {
                    Text("Developer Settings")
                }
                
                Section {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Data Source")
                            Spacer()
                            Text(accelerometerManager.useDummyData ? "Demo Data" : "Live Sensors")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Database")
                            Spacer()
                            Text(timeTracker.isDummyMode ? "Dummy DB" : "Live DB")
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Current Activity")
                            Spacer()
                            Text(nameForMETClass(accelerometerManager.currentMETClass))
                                .foregroundColor(.secondary)
                        }
                        
                        HStack {
                            Text("Confidence")
                            Spacer()
                            Text("\(Int(accelerometerManager.confidence * 100))%")
                                .foregroundColor(.secondary)
                        }
                    }
                    .font(.subheadline)
                } header: {
                    Text("Debug Information")
                }
            }
            .navigationTitle("Developer Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
        .sheet(isPresented: $showingModelSelection) {
            ModelSelectionView(accelerometerManager: accelerometerManager)
        }
    }
}

// Model Selection View
struct ModelSelectionView: View {
    @ObservedObject var accelerometerManager: AccelerometerManager
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Select Detection Model")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top)
                
                Text("Different models have varying sensitivity and accuracy characteristics")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                LazyVStack(spacing: 15) {
                    ForEach(DetectionModelType.allCases, id: \.self) { modelType in
                        ModelCard(
                            modelType: modelType,
                            isSelected: accelerometerManager.currentModel == modelType,
                            onSelect: {
                                accelerometerManager.switchModel(to: modelType)
                            }
                        )
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(10)
                .padding(.horizontal)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct ModelCard: View {
    let modelType: DetectionModelType
    let isSelected: Bool
    let onSelect: () -> Void
    
    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(modelType.rawValue)
                            .font(.headline)
                            .fontWeight(.semibold)
                        
                        Text(modelType.description)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .font(.title2)
                    }
                }
                
                // Model characteristics
                HStack(spacing: 20) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Sensitivity")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Rectangle()
                                    .fill(index < sensitivityLevel(for: modelType) ? Color.green : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 4)
                            }
                        }
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Accuracy")
                            .font(.caption2)
                            .fontWeight(.medium)
                        
                        HStack(spacing: 2) {
                            ForEach(0..<3) { index in
                                Rectangle()
                                    .fill(index < accuracyLevel(for: modelType) ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 20, height: 4)
                            }
                        }
                    }
                }
            }
            .padding()
            .background(Color(.systemBackground))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? Color.blue : Color(.systemGray4), lineWidth: isSelected ? 2 : 1)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
    
    private func sensitivityLevel(for model: DetectionModelType) -> Int {
        switch model {
        case .heuristic: return 2
        case .enhanced: return 3
        case .conservative: return 1
        case .mlModel: return 4
        }
    }
    
    private func accuracyLevel(for model: DetectionModelType) -> Int {
        switch model {
        case .heuristic: return 2
        case .enhanced: return 2
        case .conservative: return 3
        case .mlModel: return 5
        }
    }
}
