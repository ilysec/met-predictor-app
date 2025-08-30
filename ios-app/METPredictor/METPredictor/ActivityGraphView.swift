//
//  ActivityGraphView.swift
//  METPredictor
//
//  Created by Ilyas Seckin on 29.08.2025.
//

import SwiftUI

struct ActivityGraphView: View {
    let hourlyActivity: [Int]
    
    // Get current hour to only show data up to current time
    private var currentHour: Int {
        Calendar.current.component(.hour, from: Date())
    }
    
    // Check if there's any actual data (non-sedentary activity) up to current hour
    private var hasActivityData: Bool {
        for hour in 0...currentHour {
            if hour < hourlyActivity.count && hourlyActivity[hour] > 0 {
                return true
            }
        }
        return false
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Today's Activity Timeline")
                    .font(.headline)
                
                Spacer()
                
                Text("24 Hours")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            // Timeline Graph
            VStack(spacing: 8) {
                // Hour labels
                HStack(spacing: 0) {
                    ForEach(Array(stride(from: 0, to: 24, by: 4)), id: \.self) { hour in
                        Text("\(hour)")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                // Activity bars
                HStack(spacing: 1) {
                    ForEach(0..<24, id: \.self) { hour in
                        Rectangle()
                            .fill(getColorForHour(hour))
                            .frame(height: 30)
                            .cornerRadius(2)
                    }
                }
                
                // Show message if no data
                if !hasActivityData {
                    Text("No activity data recorded yet")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 5)
                } else {
                    // Legend (only show when there's data)
                    HStack(spacing: 15) {
                        ForEach(0..<4, id: \.self) { metClass in
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(colorForMETClass(metClass))
                                    .frame(width: 8, height: 8)
                                
                                Text(nameForMETClass(metClass))
                                    .font(.caption2)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                    .padding(.top, 5)
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
    
    private func getColorForHour(_ hour: Int) -> Color {
        // Future hours should be empty
        if hour > currentHour {
            return Color(.systemGray5)
        }
        
        // Past and current hours: only show data if we have recorded any non-sedentary activity
        if hour <= currentHour && hour < hourlyActivity.count && hasActivityData {
            let activityLevel = hourlyActivity[hour]
            return colorForMETClass(activityLevel)
        }
        
        // No activity data recorded or future hour - show as empty
        return Color(.systemGray5)
    }
}

struct DailyActivityChart: View {
    let dailyTimes: [Int: TimeInterval]
    
    private var totalTime: TimeInterval {
        dailyTimes.values.reduce(0, +)
    }
    
    var body: some View {
        VStack(spacing: 10) {
            Text("Activity Distribution")
                .font(.headline)
            
            if totalTime > 0 {
                GeometryReader { geometry in
                    HStack(spacing: 2) {
                        ForEach(0..<4, id: \.self) { metClass in
                            let percentage = (dailyTimes[metClass] ?? 0) / totalTime
                            let width = percentage * geometry.size.width
                            
                            Rectangle()
                                .fill(colorForMETClass(metClass))
                                .frame(width: max(width, 2))
                        }
                    }
                }
                .frame(height: 20)
                .cornerRadius(10)
                
                // Percentages
                HStack {
                    ForEach(0..<4, id: \.self) { metClass in
                        VStack(spacing: 2) {
                            Circle()
                                .fill(colorForMETClass(metClass))
                                .frame(width: 10, height: 10)
                            
                            let percentage = totalTime > 0 ? Int((dailyTimes[metClass] ?? 0) / totalTime * 100) : 0
                            Text("\(percentage)%")
                                .font(.caption2)
                                .fontWeight(.medium)
                            
                            Text(nameForMETClass(metClass))
                                .font(.caption2)
                                .foregroundColor(.secondary)
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            } else {
                Text("No activity data")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .frame(height: 60)
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

struct StatisticsPeriodView: View {
    let title: String
    let times: [Int: TimeInterval]
    let summary: String
    let hasData: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(title)
                .font(.headline)
            
            if hasData {
                // Bar Chart instead of table format
                ActivityTimeBarChart(times: times)
                
                Text(summary)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "chart.bar.xaxis")
                        .font(.system(size: 30))
                        .foregroundColor(.secondary)
                    
                    Text("No Data Available")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    
                    Text("Not enough data for this period")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(20)
                .background(Color(.systemGray6).opacity(0.3))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(15)
    }
}

struct ActivityTimeBarChart: View {
    let times: [Int: TimeInterval]
    
    private var maxTime: TimeInterval {
        times.values.max() ?? 1
    }
    
    var body: some View {
        VStack(spacing: 12) {
            Text("Time Spent by Activity")
                .font(.subheadline)
                .fontWeight(.medium)
                .foregroundColor(.secondary)
            
            VStack(spacing: 10) {
                ForEach(0..<4, id: \.self) { metClass in
                    HStack(spacing: 12) {
                        // Activity name and icon
                        HStack(spacing: 6) {
                            Circle()
                                .fill(colorForMETClass(metClass))
                                .frame(width: 12, height: 12)
                            
                            Text(nameForMETClass(metClass))
                                .font(.system(size: 14, weight: .medium))
                                .frame(width: 70, alignment: .leading)
                        }
                        
                        // Bar chart
                        GeometryReader { geometry in
                            let currentTime = times[metClass] ?? 0
                            let barWidth = maxTime > 0 ? (currentTime / maxTime) * geometry.size.width : 0
                            
                            HStack {
                                // Animated bar
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(
                                        LinearGradient(
                                            colors: [colorForMETClass(metClass), colorForMETClass(metClass).opacity(0.7)],
                                            startPoint: .leading,
                                            endPoint: .trailing
                                        )
                                    )
                                    .frame(width: barWidth, height: 24)
                                    .animation(.easeInOut(duration: 0.8), value: barWidth)
                                
                                Spacer()
                            }
                            
                            // Time label overlay
                            HStack {
                                if barWidth > 60 {
                                    // Label inside bar if there's space
                                    Text(formatTime(currentTime))
                                        .font(.system(size: 12, weight: .semibold))
                                        .foregroundColor(.white)
                                        .padding(.leading, 8)
                                    
                                    Spacer()
                                } else {
                                    // Label outside bar if not enough space
                                    Spacer()
                                    Text(formatTime(currentTime))
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.primary)
                                        .padding(.leading, 4)
                                }
                            }
                        }
                        .frame(height: 24)
                    }
                }
            }
            
            // Total time summary
            HStack {
                Spacer()
                Text("Total: \(formatTime(times.values.reduce(0, +)))")
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 8)
    }
}

#Preview {
    VStack {
        ActivityGraphView(hourlyActivity: [0, 0, 0, 0, 0, 0, 1, 1, 2, 2, 2, 1, 1, 1, 2, 2, 3, 3, 2, 1, 1, 0, 0, 0])
        
        DailyActivityChart(dailyTimes: [0: 3600, 1: 7200, 2: 1800, 3: 900])
    }
    .padding()
}
