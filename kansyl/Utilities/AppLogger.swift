//
//  AppLogger.swift
//  kansyl
//
//  Centralized logging utility with compile-time DEBUG control
//  Production builds will have zero logging overhead
//

import Foundation

struct AppLogger {
    
    // MARK: - Log Levels
    
    /// Standard informational log (DEBUG only)
    static func log(_ message: String, category: String = "App", file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("[\(category)] [\(filename):\(line)] \(message)")
        #endif
    }
    
    /// Warning log (DEBUG only)
    static func warning(_ message: String, category: String = "App", file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("⚠️ [\(category)] [\(filename):\(line)] \(message)")
        #endif
    }
    
    /// Error log (always logged, even in production)
    static func error(_ message: String, category: String = "App", file: String = #file, line: Int = #line) {
        let filename = (file as NSString).lastPathComponent
        print("❌ [\(category)] [\(filename):\(line)] \(message)")
    }
    
    /// Success log (DEBUG only)
    static func success(_ message: String, category: String = "App", file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("✅ [\(category)] [\(filename):\(line)] \(message)")
        #endif
    }
    
    /// Debug log with custom emoji (DEBUG only)
    static func debug(_ message: String, emoji: String = "🔍", category: String = "App", file: String = #file, line: Int = #line) {
        #if DEBUG
        let filename = (file as NSString).lastPathComponent
        print("\(emoji) [\(category)] [\(filename):\(line)] \(message)")
        #endif
    }
    
    // MARK: - Performance Logging
    
    /// Measure execution time of a block (DEBUG only)
    static func measure<T>(_ label: String, category: String = "Performance", block: () -> T) -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = block()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("⏱ [\(category)] \(label): \(String(format: "%.1f", elapsed))ms")
        return result
        #else
        return block()
        #endif
    }
    
    /// Measure async execution time (DEBUG only)
    static func measureAsync<T>(_ label: String, category: String = "Performance", block: () async -> T) async -> T {
        #if DEBUG
        let start = CFAbsoluteTimeGetCurrent()
        let result = await block()
        let elapsed = (CFAbsoluteTimeGetCurrent() - start) * 1000
        print("⏱ [\(category)] \(label): \(String(format: "%.1f", elapsed))ms")
        return result
        #else
        return await block()
        #endif
    }
    
    // MARK: - Conditional Logging
    
    /// Log only if condition is true (DEBUG only)
    static func logIf(_ condition: Bool, _ message: String, category: String = "App") {
        #if DEBUG
        if condition {
            print("[\(category)] \(message)")
        }
        #endif
    }
    
    // MARK: - Separator
    
    /// Print a visual separator (DEBUG only)
    static func separator(_ title: String = "", category: String = "App") {
        #if DEBUG
        if title.isEmpty {
            print("[\(category)] " + String(repeating: "-", count: 50))
        } else {
            print("[\(category)] " + String(repeating: "-", count: 20) + " \(title) " + String(repeating: "-", count: 20))
        }
        #endif
    }
}