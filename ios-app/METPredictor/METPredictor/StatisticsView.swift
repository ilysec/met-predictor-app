//
//  StatisticsView.swift
//  METPredictor
//
//  Created by Ilyas Seckin on 29.08.2025.
//

import SwiftUI

enum StatisticsTimeScale: String, CaseIterable {
    case today = "Today"
    case week = "This Week"
    case month = "This Month"
    case year = "This Year"
    
    var icon: String {
        switch self {
        case .today: return "calendar"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar.badge.plus"
        case .year: return "calendar.circle"
        }
    }
}

struct StatisticsView: View {
    @ObservedObject var timeTracker: TimeTracker
    @State private var selectedTimeScale: StatisticsTimeScale = .today
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Time Scale Selector
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(StatisticsTimeScale.allCases, id: \.self) { scale in
                            TimeScaleTab(
                                scale: scale,
                                isSelected: selectedTimeScale == scale,
                                timeTracker: timeTracker
                            ) {
                                selectedTimeScale = scale
                            }
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }
                .background(Color(.systemBackground))
                .overlay(
                    Rectangle()
                        .frame(height: 1)
                        .foregroundColor(Color(.separator)),
                    alignment: .bottom
                )
                
                // Content based on selected time scale
                ScrollView {
                    LazyVStack(spacing: 20) {
                        Group {
                            switch selectedTimeScale {
                            case .today:
                                TodayStatisticsView(timeTracker: timeTracker)
                            case .week:
                                WeekStatisticsView(timeTracker: timeTracker)
                            case .month:
                                MonthStatisticsView(timeTracker: timeTracker)
                            case .year:
                                YearStatisticsView(timeTracker: timeTracker)
                            }
                        }
                        .padding(.horizontal, 16)
                    }
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle("Statistics")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

struct TimeScaleTab: View {
    let scale: StatisticsTimeScale
    let isSelected: Bool
    let timeTracker: TimeTracker
    let action: () -> Void
    
    private var hasData: Bool {
        switch scale {
        case .today:
            return timeTracker.hasValidDailyData
        case .week:
            return timeTracker.hasValidWeeklyData
        case .month:
            return timeTracker.hasValidMonthlyData
        case .year:
            return timeTracker.hasValidYearlyData
        }
    }
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 6) {
                Image(systemName: scale.icon)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(isSelected ? .white : (hasData ? .primary : .secondary))
                
                Text(scale.rawValue)
                    .font(.caption)
                    .fontWeight(isSelected ? .semibold : .medium)
                    .foregroundColor(isSelected ? .white : (hasData ? .primary : .secondary))
                
                if !hasData && !timeTracker.isDummyMode {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 6, height: 6)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(isSelected ? Color.accentColor : Color.clear)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}

// MARK: - Individual Statistics Views

struct TodayStatisticsView: View {
    @ObservedObject var timeTracker: TimeTracker
    
    var body: some View {
        VStack(spacing: 20) {
            // Insights
            InsightsCard(
                title: "Today's Insights",
                content: timeTracker.getActivityInsights(),
                hasData: timeTracker.hasValidDailyData,
                timeTracker: timeTracker
            )
            
            // Activity Timeline Graph
            ActivityGraphView(hourlyActivity: timeTracker.hourlyActivity)
            
            // Activity Distribution
            DailyActivityChart(dailyTimes: timeTracker.dailyTimes)
            
            // Health Recommendations
            if timeTracker.hasValidDailyData {
                HealthRecommendationsView(dailyTimes: timeTracker.dailyTimes)
            }
        }
    }
}

struct WeekStatisticsView: View {
    @ObservedObject var timeTracker: TimeTracker
    
    var body: some View {
        VStack(spacing: 20) {
            // Week Overview
            StatisticsPeriodView(
                title: "This Week",
                times: timeTracker.weeklyTimes,
                summary: timeTracker.getWeeklySummary(),
                hasData: timeTracker.hasValidWeeklyData
            )
            
            // Simplified trend view only
            if timeTracker.hasValidWeeklyData {
                TrendAnalysisView(
                    timeScale: .week,
                    timeTracker: timeTracker
                )
            }
        }
    }
}

struct MonthStatisticsView: View {
    @ObservedObject var timeTracker: TimeTracker
    
    var body: some View {
        VStack(spacing: 20) {
            // Month Overview
            StatisticsPeriodView(
                title: "This Month",
                times: timeTracker.monthlyTimes,
                summary: timeTracker.getMonthlySummary(),
                hasData: timeTracker.hasValidMonthlyData
            )
            
            // Simplified trend view only
            if timeTracker.hasValidMonthlyData {
                TrendAnalysisView(
                    timeScale: .month,
                    timeTracker: timeTracker
                )
            }
        }
    }
}

struct YearStatisticsView: View {
    @ObservedObject var timeTracker: TimeTracker
    
    var body: some View {
        VStack(spacing: 20) {
            // Year Overview
            StatisticsPeriodView(
                title: "This Year",
                times: timeTracker.yearlyTimes,
                summary: timeTracker.getYearlySummary(),
                hasData: timeTracker.hasValidYearlyData
            )
            
            // Simplified trend view only
            if timeTracker.hasValidYearlyData {
                TrendAnalysisView(
                    timeScale: .year,
                    timeTracker: timeTracker
                )
            }
        }
    }
}

// MARK: - Supporting Components

struct InsightsCard: View {
    let title: String
    let content: String
    let hasData: Bool
    @ObservedObject var timeTracker: TimeTracker
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
            
            if hasData {
                Text(content)
                    .font(.body)
                    .padding()
                    .background(Color(.systemBlue).opacity(0.1))
                    .cornerRadius(15)
            } else {
                NoDataView(
                    message: timeTracker.isNewUser ? 
                        "Welcome! Start using your phone to begin tracking your activity patterns." : 
                        "Start tracking to see today's insights",
                    isNewUser: timeTracker.isNewUser
                )
            }
        }
    }
}

struct NoDataView: View {
    let message: String
    let isNewUser: Bool
    
    init(message: String, isNewUser: Bool = false) {
        self.message = message
        self.isNewUser = isNewUser
    }
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: isNewUser ? "person.badge.plus" : "chart.bar.xaxis")
                .font(.system(size: 40))
                .foregroundColor(isNewUser ? .blue : .secondary)
            
            Text(isNewUser ? "Welcome to MET Predictor!" : "No Data Available")
                .font(.headline)
                .foregroundColor(isNewUser ? .primary : .secondary)
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            if isNewUser {
                VStack(spacing: 8) {
                    Text("💡 Tip: Enable Dev Mode with dummy data to explore all features")
                        .font(.caption)
                        .foregroundColor(.blue)
                        .multilineTextAlignment(.center)
                    
                    Text("Or simply carry your phone to start tracking your real activity")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)
            }
        }
        .padding(30)
        .background(Color(.systemGray6).opacity(0.5))
        .cornerRadius(15)
    }
}

// MARK: - Trend Analysis and Supporting Components

struct TrendAnalysisView: View {
    let timeScale: StatisticsTimeScale
    @ObservedObject var timeTracker: TimeTracker
    
    private var trendData: TrendData {
        switch timeScale {
        case .week:
            return timeTracker.getWeeklyTrends()
        case .month:
            return timeTracker.getMonthlyTrends()
        case .year:
            return timeTracker.getYearlyTrends()
        default:
            return TrendData()
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Trend Analysis")
                .font(.headline)
                .fontWeight(.semibold)
            
            if !trendData.hasData {
                NoDataView(
                    message: timeTracker.isNewUser ? 
                        "Long-term trends will appear after months of regular usage." : 
                        "Not enough data for trend analysis",
                    isNewUser: timeTracker.isNewUser
                )
            } else {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 2), spacing: 16) {
                    TrendCard(
                        title: "Most Active",
                        value: trendData.mostActiveDay,
                        trend: .neutral,
                        icon: "figure.run"
                    )
                    
                    TrendCard(
                        title: "Activity Trend",
                        value: trendData.activityTrend,
                        trend: trendData.trendDirection,
                        icon: trendData.trendDirection == .up ? "arrow.up.right" : trendData.trendDirection == .down ? "arrow.down.right" : "arrow.right"
                    )
                    
                    TrendCard(
                        title: "Average Active Time",
                        value: trendData.averageActiveTime,
                        trend: .neutral,
                        icon: "clock"
                    )
                    
                    TrendCard(
                        title: "Consistency Score",
                        value: trendData.consistencyScore,
                        trend: trendData.consistencyTrend,
                        icon: "chart.line.uptrend.xyaxis"
                    )
                }
            }
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(16)
    }
}

struct TrendCard: View {
    let title: String
    let value: String
    let trend: TrendDirection
    let icon: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(.accentColor)
                
                Spacer()
                
                if trend != .neutral {
                    Image(systemName: trend == .up ? "arrow.up" : "arrow.down")
                        .font(.caption)
                        .foregroundColor(trend == .up ? .green : .red)
                }
            }
            
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(.primary)
        }
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(12)
    }
}

// MARK: - Data Structures

struct TrendData {
    let hasData: Bool
    let mostActiveDay: String
    let activityTrend: String
    let trendDirection: TrendDirection
    let averageActiveTime: String
    let consistencyScore: String
    let consistencyTrend: TrendDirection
    
    init() {
        self.hasData = false
        self.mostActiveDay = "N/A"
        self.activityTrend = "N/A"
        self.trendDirection = .neutral
        self.averageActiveTime = "N/A"
        self.consistencyScore = "N/A"
        self.consistencyTrend = .neutral
    }
    
    init(hasData: Bool, mostActiveDay: String, activityTrend: String, trendDirection: TrendDirection, averageActiveTime: String, consistencyScore: String, consistencyTrend: TrendDirection) {
        self.hasData = hasData
        self.mostActiveDay = mostActiveDay
        self.activityTrend = activityTrend
        self.trendDirection = trendDirection
        self.averageActiveTime = averageActiveTime
        self.consistencyScore = consistencyScore
        self.consistencyTrend = consistencyTrend
    }
}

enum TrendDirection {
    case up, down, neutral
}

struct HealthRecommendationsView: View {
    let dailyTimes: [Int: TimeInterval]
    
    private var recommendations: [String] {
        var recs: [String] = []
        
        let totalTime = dailyTimes.values.reduce(0, +)
        let sedentaryTime = dailyTimes[0] ?? 0
        let moderateTime = dailyTimes[2] ?? 0
        let vigorousTime = dailyTimes[3] ?? 0
        
        // WHO recommendations: 150-300 min moderate OR 75-150 min vigorous per week
        let weeklyModerate = moderateTime * 7 / 60 // Convert to minutes
        let weeklyVigorous = vigorousTime * 7 / 60
        
        if sedentaryTime / totalTime > 0.8 && totalTime > 3600 {
            recs.append("🪑 Try to reduce sedentary time - take breaks every hour")
        }
        
        if weeklyModerate < 150 && weeklyVigorous < 75 {
            recs.append("🏃‍♂️ Increase physical activity - aim for 150min moderate activity per week")
        } else {
            recs.append("✅ Great job meeting physical activity guidelines!")
        }
        
        if vigorousTime > 0 {
            recs.append("💪 Excellent vigorous activity level!")
        } else {
            recs.append("🔥 Try adding some vigorous activities like running or sports")
        }
        
        return recs
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(recommendations, id: \.self) { recommendation in
                HStack(alignment: .top, spacing: 10) {
                    Text("•")
                        .foregroundColor(.blue)
                        .fontWeight(.bold)
                    
                    Text(recommendation)
                        .font(.body)
                        .multilineTextAlignment(.leading)
                    
                    Spacer()
                }
            }
        }
        .padding()
        .background(Color(.systemGreen).opacity(0.1))
        .cornerRadius(15)
    }
}

struct WeeklyComparisonView: View {
    let weeklyTimes: [Int: TimeInterval]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Weekly Progress")
                .font(.headline)
            
            // Simple weekly comparison bars
            VStack(spacing: 8) {
                ForEach(0..<4, id: \.self) { metClass in
                    HStack {
                        Text(nameForMETClass(metClass))
                            .font(.caption)
                            .frame(width: 80, alignment: .leading)
                        
                        GeometryReader { geometry in
                            let maxTime = weeklyTimes.values.max() ?? 1
                            let currentTime = weeklyTimes[metClass] ?? 0
                            let width = (currentTime / maxTime) * geometry.size.width
                            
                            HStack {
                                Rectangle()
                                    .fill(colorForMETClass(metClass))
                                    .frame(width: width, height: 15)
                                    .cornerRadius(7.5)
                                
                                Spacer()
                            }
                        }
                        .frame(height: 15)
                        
                        Text(formatTime(weeklyTimes[metClass] ?? 0))
                            .font(.caption)
                            .frame(width: 50, alignment: .trailing)
                    }
                }
            }
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(15)
    }
}

#Preview {
    StatisticsView(timeTracker: TimeTracker())
}
