import Foundation
import Combine

class TimeTracker: ObservableObject {
    @Published var dailyTimes: [Int: TimeInterval] = [
        0: 0, // Sedentary
        1: 0, // Light
        2: 0, // Moderate
        3: 0  // Vigorous
    ]
    
    @Published var weeklyTimes: [Int: TimeInterval] = [
        0: 0, 1: 0, 2: 0, 3: 0
    ]
    
    @Published var monthlyTimes: [Int: TimeInterval] = [
        0: 0, 1: 0, 2: 0, 3: 0
    ]
    
    @Published var yearlyTimes: [Int: TimeInterval] = [
        0: 0, 1: 0, 2: 0, 3: 0
    ]
    
    @Published var hourlyActivity: [Int] = Array(repeating: 0, count: 24) // Track dominant activity per hour
    @Published var isDummyMode: Bool = false
    
    private var currentMETClass: Int = 0
    private var lastUpdateTime: Date = Date()
    private var timer: Timer?
    private var dummyDataTimer: Timer? // Timer for continuous dummy data generation
    
    init() {
        // Always start in live mode for production use
        clearDummyMode()
        
        // Load live user data
        loadLiveData()
        
        startTimer()
    }
    
    deinit {
        timer?.invalidate()
        dummyDataTimer?.invalidate()
        
        if isDummyMode {
            saveDummyData()
        } else {
            saveLiveData()
        }
    }
    
        // MARK: - Database Management
    
    private func getDatabasePrefix() -> String {
        return isDummyMode ? "Dummy_" : "Live_"
    }
    
    private func loadDummyData() {
        loadData(withPrefix: "Dummy_")
        // Generate initial dummy data if none exists
        if !hasAnyDummyData() {
            generateComprehensiveDummyData()
        }
    }
    
    private func loadLiveData() {
        loadData(withPrefix: "Live_")
    }
    
    private func loadData(withPrefix prefix: String) {
        print("🎯 DEBUG: Loading data with prefix: \(prefix)")
        loadDailyTimes(prefix: prefix)
        loadWeeklyTimes(prefix: prefix)
        loadMonthlyTimes(prefix: prefix)
        loadYearlyTimes(prefix: prefix)
        loadHourlyActivity(prefix: prefix)
        print("🎯 DEBUG: Data loaded - daily times: \(dailyTimes), hourly activity: \(hourlyActivity)")
    }
    
    private func saveDummyData() {
        saveData(withPrefix: "Dummy_")
    }
    
    private func saveLiveData() {
        saveData(withPrefix: "Live_")
    }
    
    private func saveData(withPrefix prefix: String) {
        saveDailyTimes(prefix: prefix)
        saveWeeklyTimes(prefix: prefix)
        saveMonthlyTimes(prefix: prefix)
        saveYearlyTimes(prefix: prefix)
        saveHourlyActivity(prefix: prefix)
    }
    
    private func hasAnyDummyData() -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "Dummy_DailyTimes_\(today.timeIntervalSince1970)"
        return UserDefaults.standard.object(forKey: key) != nil
    }
    
    private func loadDummyMode() {
        isDummyMode = UserDefaults.standard.bool(forKey: "DummyMode")
        // Don't automatically calculate dummy data here - let it be explicit
    }
    
    private func saveDummyMode() {
        UserDefaults.standard.set(isDummyMode, forKey: "DummyMode")
    }
    
    private func clearDummyMode() {
        UserDefaults.standard.removeObject(forKey: "DummyMode")
        UserDefaults.standard.removeObject(forKey: "AccelerometerUseDummyData")
        isDummyMode = false
        print("🎯 DEBUG: Cleared dummy mode preference - app will start in live mode")
    }
    
    func enableDummyMode() {
        print("🎯 DEBUG: Enabling dummy mode")
        
        // Save current live data before switching
        if !isDummyMode {
            saveLiveData()
        }
        
        isDummyMode = true
        saveDummyMode()
        
        // Always regenerate fresh dummy data to ensure it's current
        generateComprehensiveDummyData()
        
        // Load the generated dummy data into display variables
        loadDummyData()
        
        // Start live dummy data generation
        startDummyDataGeneration()
        
        print("🎯 DEBUG: Dummy mode enabled - daily times: \(dailyTimes)")
        print("🎯 DEBUG: Weekly times: \(weeklyTimes)")
        print("🎯 DEBUG: Hourly activity: \(hourlyActivity)")
    }
    
    func disableDummyMode() {
        print("🎯 DEBUG: Disabling dummy mode")
        
        // Save dummy data before switching
        if isDummyMode {
            saveDummyData()
            dummyDataTimer?.invalidate()
        }
        
        isDummyMode = false
        loadLiveData()
        saveDummyMode()
        
        print("🎯 DEBUG: Dummy mode disabled - daily times: \(dailyTimes)")
        print("🎯 DEBUG: Weekly times: \(weeklyTimes)")
        print("🎯 DEBUG: Hourly activity: \(hourlyActivity)")
    }
    
    // MARK: - Dummy Data Generation
    
    private func startDummyDataGeneration() {
        // Start continuous data generation for demo purposes
        dummyDataTimer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.generateLiveDummyData()
        }
    }
    
    private func generateLiveDummyData() {
        // Simulate realistic activity patterns
        let currentHour = Calendar.current.component(.hour, from: Date())
        
        // Time-based activity simulation
        let activityClass: Int
        let duration: TimeInterval = 5.0 // 5 seconds of simulated activity
        
        switch currentHour {
        case 6...8: // Morning routine
            activityClass = [0, 1, 1, 2].randomElement() ?? 1
        case 9...17: // Work hours
            activityClass = [0, 0, 0, 1].randomElement() ?? 0
        case 18...21: // Evening
            activityClass = [1, 1, 2, 3].randomElement() ?? 1
        case 22...23, 0...5: // Night
            activityClass = 0
        default:
            activityClass = 0
        }
        
        // Update dummy data with simulated activity
        updateDummyTime(activityClass: activityClass, duration: duration)
    }
    
    private func updateDummyTime(activityClass: Int, duration: TimeInterval) {
        // Update current displayed data
        dailyTimes[activityClass, default: 0] += duration
        weeklyTimes[activityClass, default: 0] += duration
        monthlyTimes[activityClass, default: 0] += duration
        yearlyTimes[activityClass, default: 0] += duration
        
        // Update hourly activity
        let currentHour = Calendar.current.component(.hour, from: Date())
        if currentHour >= 0 && currentHour < 24 {
            hourlyActivity[currentHour] = activityClass
        }
        
        // Save to dummy database
        saveDummyData()
    }
    
    private func generateComprehensiveDummyData() {
        let calendar = Calendar.current
        let now = Date()
        
        print("🎯 DEBUG: Starting comprehensive dummy data generation")
        
        // Generate last year of realistic data
        for daysBack in 1...365 {
            guard let date = calendar.date(byAdding: .day, value: -daysBack, to: now) else { continue }
            generateDummyDataForDate(date, prefix: "Dummy_")
        }
        
        // Generate today's data
        generateDummyDataForDate(now, prefix: "Dummy_")
        generateDummyHourlyPattern(prefix: "Dummy_")
        
        // Calculate aggregated data from generated daily data
        calculateAggregatedData(prefix: "Dummy_")
        
        // IMPORTANT: Load the generated data into current display variables
        loadData(withPrefix: "Dummy_")
        
        print("🎯 DEBUG: Comprehensive dummy data generation completed")
        print("🎯 DEBUG: Daily times after generation: \(dailyTimes)")
        print("🎯 DEBUG: Weekly times after generation: \(weeklyTimes)")
        print("🎯 DEBUG: Hourly activity after generation: \(hourlyActivity)")
    }
    
    private func generateDummyDataForDate(_ date: Date, prefix: String) {
        // Realistic daily patterns with some randomness
        let dayOfWeek = Calendar.current.component(.weekday, from: date)
        let isWeekend = dayOfWeek == 1 || dayOfWeek == 7
        
        // Base patterns (in hours)
        var sedentaryHours: Double
        var lightHours: Double
        var moderateHours: Double
        var vigorousHours: Double
        
        if isWeekend {
            // More varied weekend patterns
            sedentaryHours = Double.random(in: 6...10)
            lightHours = Double.random(in: 3...6)
            moderateHours = Double.random(in: 1...3)
            vigorousHours = Double.random(in: 0...2)
        } else {
            // More sedentary weekdays
            sedentaryHours = Double.random(in: 8...12)
            lightHours = Double.random(in: 2...4)
            moderateHours = Double.random(in: 0.5...2)
            vigorousHours = Double.random(in: 0...1)
        }
        
        // Add seasonal variation
        let month = Calendar.current.component(.month, from: date)
        let seasonalMultiplier: Double
        switch month {
        case 6...8: // Summer - more active
            seasonalMultiplier = 1.2
        case 12, 1, 2: // Winter - less active
            seasonalMultiplier = 0.8
        default: // Spring/Fall
            seasonalMultiplier = 1.0
        }
        
        lightHours *= seasonalMultiplier
        moderateHours *= seasonalMultiplier
        vigorousHours *= seasonalMultiplier
        
        // Convert to seconds and save
        let dayStart = Calendar.current.startOfDay(for: date)
        let key = "\(prefix)DailyTimes_\(dayStart.timeIntervalSince1970)"
        
        let data: [String: TimeInterval] = [
            "sedentary": sedentaryHours * 3600,
            "light": lightHours * 3600,
            "moderate": moderateHours * 3600,
            "vigorous": vigorousHours * 3600,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func generateDummyHourlyPattern(prefix: String) {
        var pattern = Array(repeating: 0, count: 24)
        
        // Morning routine (6-9): Light activity
        for hour in 6...8 {
            pattern[hour] = [0, 1].randomElement() ?? 0
        }
        
        // Work hours (9-17): Mostly sedentary with some light
        for hour in 9...17 {
            pattern[hour] = [0, 0, 0, 1].randomElement() ?? 0
        }
        
        // Evening (18-22): Mixed activity
        for hour in 18...21 {
            pattern[hour] = [0, 1, 2].randomElement() ?? 1
        }
        
        // Night (22-6): Sedentary
        for hour in [22, 23, 0, 1, 2, 3, 4, 5] {
            pattern[hour] = 0
        }
        
        // Add occasional vigorous activity
        if Bool.random() {
            let vigorousHour = [7, 8, 18, 19, 20].randomElement() ?? 19
            pattern[vigorousHour] = 3
        }
        
        hourlyActivity = pattern
        saveHourlyActivity(prefix: prefix)
    }
    
    private func calculateAggregatedData(prefix: String) {
        let calendar = Calendar.current
        let now = Date()
        
        // Calculate weekly totals
        let weekStart = calendar.dateInterval(of: .weekOfYear, for: now)?.start ?? now
        var weeklyTotals: [Int: TimeInterval] = [0: 0, 1: 0, 2: 0, 3: 0]
        
        for day in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: day, to: weekStart) {
                let dayStart = calendar.startOfDay(for: date)
                let key = "\(prefix)DailyTimes_\(dayStart.timeIntervalSince1970)"
                
                if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
                    weeklyTotals[0]! += data["sedentary"] ?? 0
                    weeklyTotals[1]! += data["light"] ?? 0
                    weeklyTotals[2]! += data["moderate"] ?? 0
                    weeklyTotals[3]! += data["vigorous"] ?? 0
                }
            }
        }
        
        // Save weekly data
        let weekKey = "\(prefix)WeeklyTimes_\(weekStart.timeIntervalSince1970)"
        let weekData: [String: TimeInterval] = [
            "sedentary": weeklyTotals[0]!,
            "light": weeklyTotals[1]!,
            "moderate": weeklyTotals[2]!,
            "vigorous": weeklyTotals[3]!,
            "lastSaved": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(weekData, forKey: weekKey)
        
        // Calculate monthly totals
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        var monthlyTotals: [Int: TimeInterval] = [0: 0, 1: 0, 2: 0, 3: 0]
        
        for day in 0..<30 {
            if let date = calendar.date(byAdding: .day, value: day, to: monthStart) {
                let dayStart = calendar.startOfDay(for: date)
                let key = "\(prefix)DailyTimes_\(dayStart.timeIntervalSince1970)"
                
                if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
                    monthlyTotals[0]! += data["sedentary"] ?? 0
                    monthlyTotals[1]! += data["light"] ?? 0
                    monthlyTotals[2]! += data["moderate"] ?? 0
                    monthlyTotals[3]! += data["vigorous"] ?? 0
                }
            }
        }
        
        // Save monthly data
        let monthKey = "\(prefix)MonthlyTimes_\(monthStart.timeIntervalSince1970)"
        let monthData: [String: TimeInterval] = [
            "sedentary": monthlyTotals[0]!,
            "light": monthlyTotals[1]!,
            "moderate": monthlyTotals[2]!,
            "vigorous": monthlyTotals[3]!,
            "lastSaved": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(monthData, forKey: monthKey)
        
        // Calculate yearly totals (simplified - just multiply weekly by ~52)
        let yearMultiplier = 52.0
        let yearlyTotals = [
            0: weeklyTotals[0]! * yearMultiplier + Double.random(in: -50000...50000),
            1: weeklyTotals[1]! * yearMultiplier + Double.random(in: -20000...20000),
            2: weeklyTotals[2]! * yearMultiplier + Double.random(in: -10000...10000),
            3: weeklyTotals[3]! * yearMultiplier + Double.random(in: -5000...5000)
        ]
        
        // Save yearly data
        let yearStart = calendar.dateInterval(of: .year, for: now)?.start ?? now
        let yearKey = "\(prefix)YearlyTimes_\(yearStart.timeIntervalSince1970)"
        let yearData: [String: TimeInterval] = [
            "sedentary": yearlyTotals[0]!,
            "light": yearlyTotals[1]!,
            "moderate": yearlyTotals[2]!,
            "vigorous": yearlyTotals[3]!,
            "lastSaved": Date().timeIntervalSince1970
        ]
        UserDefaults.standard.set(yearData, forKey: yearKey)
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTime()
        }
    }
    
    func updateCurrentActivity(metClass: Int) {
        updateTime() // Update time for previous activity
        currentMETClass = metClass
        lastUpdateTime = Date()
    }
    
    private func updateTime() {
        // Only update live data in live mode
        if isDummyMode {
            return
        }
        
        let now = Date()
        let timeElapsed = now.timeIntervalSince(lastUpdateTime)
        
        // Handle app being inactive: don't catch up on missed time
        // Just reset the timer and start fresh
        if timeElapsed > 30 { // If more than 30 seconds have passed
            print("App was inactive for \(timeElapsed) seconds - starting fresh")
            lastUpdateTime = now
            return
        }
        
        if timeElapsed > 0 && timeElapsed < 10 { // Normal operation: update within 10 seconds
            // Update daily times
            dailyTimes[currentMETClass, default: 0] += timeElapsed
            
            // Update weekly times
            weeklyTimes[currentMETClass, default: 0] += timeElapsed
            
            // Update monthly times
            monthlyTimes[currentMETClass, default: 0] += timeElapsed
            
            // Update yearly times
            yearlyTimes[currentMETClass, default: 0] += timeElapsed
            
            // Update hourly activity
            let currentHour = Calendar.current.component(.hour, from: now)
            updateHourlyActivity(hour: currentHour, metClass: currentMETClass, duration: timeElapsed)
        }
        
        lastUpdateTime = now
        
        // Auto-save every minute for live data
        if Int(dailyTimes.values.reduce(0, +)) % 60 == 0 {
            saveLiveData()
        }
    }
    
    func resetDailyTimes() {
        if isDummyMode {
            // In dummy mode, regenerate today's data
            generateDummyDataForDate(Date(), prefix: "Dummy_")
            generateDummyHourlyPattern(prefix: "Dummy_")
            loadDummyData()
        } else {
            // In live mode, reset current tracking
            dailyTimes = [0: 0, 1: 0, 2: 0, 3: 0]
            hourlyActivity = Array(repeating: 0, count: 24)
            lastUpdateTime = Date()
            saveLiveData()
        }
    }
    
    private func saveDailyTimes(prefix: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(prefix)DailyTimes_\(today.timeIntervalSince1970)"
        
        let data: [String: TimeInterval] = [
            "sedentary": dailyTimes[0] ?? 0,
            "light": dailyTimes[1] ?? 0,
            "moderate": dailyTimes[2] ?? 0,
            "vigorous": dailyTimes[3] ?? 0,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func loadDailyTimes(prefix: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(prefix)DailyTimes_\(today.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
            dailyTimes = [
                0: data["sedentary"] ?? 0,
                1: data["light"] ?? 0,
                2: data["moderate"] ?? 0,
                3: data["vigorous"] ?? 0
            ]
        } else {
            // No data exists for this prefix - initialize with zeros
            dailyTimes = [0: 0, 1: 0, 2: 0, 3: 0]
        }
    }
    
    private func loadWeeklyTimes(prefix: String) {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let key = "\(prefix)WeeklyTimes_\(weekStart.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
            weeklyTimes = [
                0: data["sedentary"] ?? 0,
                1: data["light"] ?? 0,
                2: data["moderate"] ?? 0,
                3: data["vigorous"] ?? 0
            ]
        } else {
            // No data exists for this prefix - initialize with zeros
            weeklyTimes = [0: 0, 1: 0, 2: 0, 3: 0]
        }
    }
    
    private func loadYearlyTimes(prefix: String) {
        let yearStart = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()
        let key = "\(prefix)YearlyTimes_\(yearStart.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
            yearlyTimes = [
                0: data["sedentary"] ?? 0,
                1: data["light"] ?? 0,
                2: data["moderate"] ?? 0,
                3: data["vigorous"] ?? 0
            ]
        } else {
            // No data exists for this prefix - initialize with zeros
            yearlyTimes = [0: 0, 1: 0, 2: 0, 3: 0]
        }
    }
    
    private func loadHourlyActivity(prefix: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(prefix)HourlyActivity_\(today.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.array(forKey: key) as? [Int] {
            hourlyActivity = data
        } else {
            // No data exists for this prefix - initialize with zeros
            hourlyActivity = Array(repeating: 0, count: 24)
        }
    }
    
    private func saveWeeklyTimes(prefix: String) {
        let weekStart = Calendar.current.dateInterval(of: .weekOfYear, for: Date())?.start ?? Date()
        let key = "\(prefix)WeeklyTimes_\(weekStart.timeIntervalSince1970)"
        
        let data: [String: TimeInterval] = [
            "sedentary": weeklyTimes[0] ?? 0,
            "light": weeklyTimes[1] ?? 0,
            "moderate": weeklyTimes[2] ?? 0,
            "vigorous": weeklyTimes[3] ?? 0,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func saveYearlyTimes(prefix: String) {
        let yearStart = Calendar.current.dateInterval(of: .year, for: Date())?.start ?? Date()
        let key = "\(prefix)YearlyTimes_\(yearStart.timeIntervalSince1970)"
        
        let data: [String: TimeInterval] = [
            "sedentary": yearlyTimes[0] ?? 0,
            "light": yearlyTimes[1] ?? 0,
            "moderate": yearlyTimes[2] ?? 0,
            "vigorous": yearlyTimes[3] ?? 0,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    private func saveHourlyActivity(prefix: String) {
        let today = Calendar.current.startOfDay(for: Date())
        let key = "\(prefix)HourlyActivity_\(today.timeIntervalSince1970)"
        
        UserDefaults.standard.set(hourlyActivity, forKey: key)
    }
    
    private func updateHourlyActivity(hour: Int, metClass: Int, duration: TimeInterval) {
        // Store the dominant activity for each hour
        // Simple approach: current activity overwrites the hour
        if hour >= 0 && hour < 24 {
            hourlyActivity[hour] = metClass
        }
    }
    
    // Helper method to get formatted daily summary
    func getDailySummary() -> String {
        let total = dailyTimes.values.reduce(0, +)
        guard total > 0 else { return "No activity tracked today" }
        
        let sedentaryPercent = Int((dailyTimes[0] ?? 0) / total * 100)
        let lightPercent = Int((dailyTimes[1] ?? 0) / total * 100)
        let moderatePercent = Int((dailyTimes[2] ?? 0) / total * 100)
        let vigorousPercent = Int((dailyTimes[3] ?? 0) / total * 100)
        
        return """
        Daily Activity Summary:
        • Sedentary: \(sedentaryPercent)%
        • Light: \(lightPercent)%
        • Moderate: \(moderatePercent)%
        • Vigorous: \(vigorousPercent)%
        Total tracked: \(formatDuration(total))
        """
    }
    
    func getWeeklySummary() -> String {
        let total = weeklyTimes.values.reduce(0, +)
        guard total > 0 else { return "No activity tracked this week" }
        
        let sedentaryPercent = Int((weeklyTimes[0] ?? 0) / total * 100)
        let lightPercent = Int((weeklyTimes[1] ?? 0) / total * 100)
        let moderatePercent = Int((weeklyTimes[2] ?? 0) / total * 100)
        let vigorousPercent = Int((weeklyTimes[3] ?? 0) / total * 100)
        
        return """
        Weekly Activity Summary:
        • Sedentary: \(sedentaryPercent)%
        • Light: \(lightPercent)%
        • Moderate: \(moderatePercent)%
        • Vigorous: \(vigorousPercent)%
        Total tracked: \(formatDuration(total))
        """
    }
    
    func getYearlySummary() -> String {
        let total = yearlyTimes.values.reduce(0, +)
        guard total > 0 else { return "No activity tracked this year" }
        
        let sedentaryPercent = Int((yearlyTimes[0] ?? 0) / total * 100)
        let lightPercent = Int((yearlyTimes[1] ?? 0) / total * 100)
        let moderatePercent = Int((yearlyTimes[2] ?? 0) / total * 100)
        let vigorousPercent = Int((yearlyTimes[3] ?? 0) / total * 100)
        
        return """
        Yearly Activity Summary:
        • Sedentary: \(sedentaryPercent)%
        • Light: \(lightPercent)%
        • Moderate: \(moderatePercent)%
        • Vigorous: \(vigorousPercent)%
        Total tracked: \(formatDuration(total))
        """
    }
    
    func getActivityInsights() -> String {
        let dailyTotal = dailyTimes.values.reduce(0, +)
        let weeklyTotal = weeklyTimes.values.reduce(0, +)
        
        guard dailyTotal > 0 else { return "Start tracking to see insights!" }
        
        let activeTime = (dailyTimes[1] ?? 0) + (dailyTimes[2] ?? 0) + (dailyTimes[3] ?? 0)
        let activePercent = Int(activeTime / dailyTotal * 100)
        
        let weeklyAvgDaily = weeklyTotal / 7
        let todayVsAvg = dailyTotal > weeklyAvgDaily ? "above" : "below"
        
        return """
        📊 Today's Insights:
        • \(activePercent)% active time
        • \(formatDuration(activeTime)) active today
        • You're \(todayVsAvg) weekly average
        • Peak activity: \(getPeakActivityHour())
        """
    }
    
    private func getPeakActivityHour() -> String {
        var maxActivityHour = 0
        var maxActivityLevel = 0
        
        for (hour, activity) in hourlyActivity.enumerated() {
            if activity > maxActivityLevel {
                maxActivityLevel = activity
                maxActivityHour = hour
            }
        }
        
        return "\(maxActivityHour):00 (\(nameForMETClass(maxActivityLevel)))"
    }
    
    private func formatDuration(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    // MARK: - Data Validation Methods
    
    var hasValidDailyData: Bool {
        // In dummy mode, we always have valid data
        if isDummyMode { return true }
        
        // In live mode, check for actual tracked time (excluding dummy data)
        let totalTime = dailyTimes.values.reduce(0, +)
        return totalTime > 600 // At least 10 minutes of real data
    }
    
    var hasValidWeeklyData: Bool {
        // In dummy mode, we always have valid data
        if isDummyMode { return true }
        
        // In live mode, check for actual historical data (not dummy generated)
        let totalTime = weeklyTimes.values.reduce(0, +)
        return totalTime > 3600 // At least 1 hour of real data across the week
    }
    
    var hasValidMonthlyData: Bool {
        // In dummy mode, we always have valid data
        if isDummyMode { return true }
        
        // In live mode, check for actual historical data (not dummy generated)
        let totalTime = monthlyTimes.values.reduce(0, +)
        return totalTime > 7200 // At least 2 hours of real data across the month
    }
    
    var hasValidYearlyData: Bool {
        // In dummy mode, we always have valid data
        if isDummyMode { return true }
        
        // In live mode, check for actual historical data (not dummy generated)
        let totalTime = yearlyTimes.values.reduce(0, +)
        return totalTime > 21600 // At least 6 hours of real data across the year
    }
    
    // MARK: - New User Detection
    
    /// Check if this is a completely new user with no historical data
    var isNewUser: Bool {
        // If in dummy mode, not a new user
        if isDummyMode { return false }
        
        // Check if there's any real data stored
        let hasDailyData = dailyTimes.values.reduce(0, +) > 0
        let hasWeeklyData = weeklyTimes.values.reduce(0, +) > 0
        let hasMonthlyData = monthlyTimes.values.reduce(0, +) > 0
        let hasYearlyData = yearlyTimes.values.reduce(0, +) > 0
        
        return !hasDailyData && !hasWeeklyData && !hasMonthlyData && !hasYearlyData
    }
    
    // MARK: - Monthly Data Management
    
    private func loadMonthlyTimes(prefix: String) {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let key = "\(prefix)MonthlyTimes_\(monthStart.timeIntervalSince1970)"
        
        if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
            monthlyTimes = [
                0: data["sedentary"] ?? 0,
                1: data["light"] ?? 0,
                2: data["moderate"] ?? 0,
                3: data["vigorous"] ?? 0
            ]
        } else {
            // No data exists for this prefix - initialize with zeros
            monthlyTimes = [0: 0, 1: 0, 2: 0, 3: 0]
        }
    }
    
    private func saveMonthlyTimes(prefix: String) {
        let calendar = Calendar.current
        let now = Date()
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let key = "\(prefix)MonthlyTimes_\(monthStart.timeIntervalSince1970)"
        
        let data: [String: TimeInterval] = [
            "sedentary": monthlyTimes[0] ?? 0,
            "light": monthlyTimes[1] ?? 0,
            "moderate": monthlyTimes[2] ?? 0,
            "vigorous": monthlyTimes[3] ?? 0,
            "lastSaved": Date().timeIntervalSince1970
        ]
        
        UserDefaults.standard.set(data, forKey: key)
    }
    
    func getMonthlySummary() -> String {
        if !hasValidMonthlyData {
            return "Not enough data for monthly insights. Keep tracking to see patterns."
        }
        
        let totalTime = monthlyTimes.values.reduce(0, +)
        let activeTime = (monthlyTimes[1] ?? 0) + (monthlyTimes[2] ?? 0) + (monthlyTimes[3] ?? 0)
        let activePercent = totalTime > 0 ? Int((activeTime / totalTime) * 100) : 0
        
        return """
        📅 Monthly Summary:
        • \(activePercent)% active time this month
        • \(formatDuration(activeTime)) total active time
        • Daily average: \(formatDuration(activeTime / 30))
        """
    }
    
    // MARK: - Breakdown Data Methods
    
    func getWeeklyBreakdownData() -> [(String, [Double])] {
        guard hasValidWeeklyData else { 
            print("🔍 DEBUG: No valid weekly data - isDummyMode: \(isDummyMode)")
            return [] 
        }
        
        let calendar = Calendar.current
        let now = Date()
        let prefix = getDatabasePrefix()
        var result: [(String, [Double])] = []
        
        print("🔍 DEBUG: Getting weekly breakdown data with prefix: \(prefix)")
        
        // Debug: Show all UserDefaults keys with this prefix
        let allKeys = UserDefaults.standard.dictionaryRepresentation().keys
        let relevantKeys = allKeys.filter { $0.contains(prefix) && $0.contains("DailyTimes") }
        print("🔍 DEBUG: Found \(relevantKeys.count) relevant keys: \(relevantKeys)")
        
        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -6 + i, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let key = "\(prefix)DailyTimes_\(dayStart.timeIntervalSince1970)"
            
            let dayName = calendar.isDateInToday(date) ? "Today" : 
                         calendar.isDateInYesterday(date) ? "Yesterday" :
                         DateFormatter().weekdaySymbols[calendar.component(.weekday, from: date) - 1].prefix(3).description
            
            print("🔍 DEBUG: Checking day \(dayName) (\(dayStart)) with key: \(key)")
            
            if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
                let total = data.values.reduce(0, +)
                let percentages = total > 0 ? [
                    (data["sedentary"] ?? 0) / total * 100,
                    (data["light"] ?? 0) / total * 100,
                    (data["moderate"] ?? 0) / total * 100,
                    (data["vigorous"] ?? 0) / total * 100
                ] : [0, 0, 0, 0]
                
                print("🔍 DEBUG: Day \(dayName), total: \(total), percentages: \(percentages)")
                result.append((dayName, percentages))
            } else {
                print("🔍 DEBUG: No data for day \(dayName), key: \(key)")
                result.append((dayName, [0, 0, 0, 0]))
            }
        }
        
        print("🔍 DEBUG: Final weekly breakdown result: \(result)")
        return result
    }
    
    func getMonthlyBreakdownData() -> [(String, [Double])] {
        guard hasValidMonthlyData else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let prefix = getDatabasePrefix()
        var result: [(String, [Double])] = []
        
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -29 + i, to: now) else { continue }
            let dayStart = calendar.startOfDay(for: date)
            let key = "\(prefix)DailyTimes_\(dayStart.timeIntervalSince1970)"
            
            let dayLabel = "\(calendar.component(.day, from: date))"
            
            if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
                let total = data.values.reduce(0, +)
                let percentages = total > 0 ? [
                    (data["sedentary"] ?? 0) / total * 100,
                    (data["light"] ?? 0) / total * 100,
                    (data["moderate"] ?? 0) / total * 100,
                    (data["vigorous"] ?? 0) / total * 100
                ] : [0, 0, 0, 0]
                
                result.append((dayLabel, percentages))
            } else {
                result.append((dayLabel, [0, 0, 0, 0]))
            }
        }
        
        return result
    }
    
    func getYearlyBreakdownData() -> [(String, [Double])] {
        guard hasValidYearlyData else { return [] }
        
        let calendar = Calendar.current
        let now = Date()
        let prefix = getDatabasePrefix()
        var result: [(String, [Double])] = []
        
        for i in 0..<12 {
            guard let date = calendar.date(byAdding: .month, value: -11 + i, to: now) else { continue }
            let monthStart = calendar.dateInterval(of: .month, for: date)?.start ?? date
            let key = "\(prefix)MonthlyTimes_\(monthStart.timeIntervalSince1970)"
            
            let monthName = DateFormatter().shortMonthSymbols[calendar.component(.month, from: date) - 1]
            
            if let data = UserDefaults.standard.object(forKey: key) as? [String: TimeInterval] {
                let total = data.values.reduce(0, +)
                let percentages = total > 0 ? [
                    (data["sedentary"] ?? 0) / total * 100,
                    (data["light"] ?? 0) / total * 100,
                    (data["moderate"] ?? 0) / total * 100,
                    (data["vigorous"] ?? 0) / total * 100
                ] : [0, 0, 0, 0]
                
                result.append((monthName, percentages))
            } else {
                result.append((monthName, [0, 0, 0, 0]))
            }
        }
        
        return result
    }
    
    // MARK: - Trend Analysis Methods
    
    func getWeeklyTrends() -> TrendData {
        guard hasValidWeeklyData else { return TrendData() }
        
        let breakdownData = getWeeklyBreakdownData()
        let mostActiveDay = findMostActiveDay(breakdownData)
        let averageActiveTime = calculateAverageActiveTime(weeklyTimes, days: 7)
        
        return TrendData(
            hasData: true,
            mostActiveDay: mostActiveDay,
            activityTrend: "Stable",
            trendDirection: .neutral,
            averageActiveTime: averageActiveTime,
            consistencyScore: "Good",
            consistencyTrend: .neutral
        )
    }
    
    func getMonthlyTrends() -> TrendData {
        guard hasValidMonthlyData else { return TrendData() }
        
        let averageActiveTime = calculateAverageActiveTime(monthlyTimes, days: 30)
        
        return TrendData(
            hasData: true,
            mostActiveDay: "Weekdays",
            activityTrend: "Improving",
            trendDirection: .up,
            averageActiveTime: averageActiveTime,
            consistencyScore: "Excellent",
            consistencyTrend: .up
        )
    }
    
    func getYearlyTrends() -> TrendData {
        guard hasValidYearlyData else { return TrendData() }
        
        let averageActiveTime = calculateAverageActiveTime(yearlyTimes, days: 365)
        
        return TrendData(
            hasData: true,
            mostActiveDay: "Summer months",
            activityTrend: "Seasonal",
            trendDirection: .neutral,
            averageActiveTime: averageActiveTime,
            consistencyScore: "Good",
            consistencyTrend: .neutral
        )
    }
    
    private func findMostActiveDay(_ breakdownData: [(String, [Double])]) -> String {
        var maxActiveDay = "N/A"
        var maxActivePercentage = 0.0
        
        for (day, percentages) in breakdownData {
            let activePercentage = percentages[1] + percentages[2] + percentages[3] // Light + Moderate + Vigorous
            if activePercentage > maxActivePercentage {
                maxActivePercentage = activePercentage
                maxActiveDay = day
            }
        }
        
        return maxActiveDay
    }
    
    private func calculateAverageActiveTime(_ times: [Int: TimeInterval], days: Int) -> String {
        let activeTime = (times[1] ?? 0) + (times[2] ?? 0) + (times[3] ?? 0)
        let averageDaily = activeTime / Double(days)
        return formatDuration(averageDaily)
    }
    
    // MARK: - Enhanced Reset Method
}
