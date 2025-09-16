//
//  SavingsChartView.swift
//  kansyl
//
//  Created on 9/12/25.
//

import SwiftUI

struct MonthData: Identifiable {
    let id = UUID()
    let month: String
    let savings: Double
    let waste: Double
    
    var total: Double { savings + waste }
}

struct SavingsChartView: View {
    let monthlyData: [MonthData]
    @State private var selectedMonth: MonthData?
    @State private var animateChart = false
    
    private let maxHeight: CGFloat = 200
    
    var maxValue: Double {
        monthlyData.map { $0.total }.max() ?? 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Chart
            HStack(alignment: .bottom, spacing: 8) {
                ForEach(monthlyData) { data in
                    VStack(spacing: 0) {
                        // Bar
                        VStack(spacing: 0) {
                            // Waste portion
                            if data.waste > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.red.opacity(0.7))
                                    .frame(height: animateChart ? CGFloat(data.waste / maxValue) * maxHeight : 0)
                            }
                            
                            // Savings portion
                            if data.savings > 0 {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.green.opacity(0.8))
                                    .frame(height: animateChart ? CGFloat(data.savings / maxValue) * maxHeight : 0)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.gray.opacity(0.1))
                                .frame(height: maxHeight)
                        )
                        .onTapGesture {
                            withAnimation(.easeInOut(duration: 0.2)) {
                                if selectedMonth?.id == data.id {
                                    selectedMonth = nil
                                } else {
                                    selectedMonth = data
                                    let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                    impactFeedback.impactOccurred()
                                }
                            }
                        }
                        
                        // Month label
                        Text(data.month)
                            .font(.caption2)
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: maxHeight + 20)
            
            // Legend
            HStack(spacing: 20) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.green.opacity(0.8))
                        .frame(width: 10, height: 10)
                    Text("Saved")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                HStack(spacing: 4) {
                    Circle()
                        .fill(Color.red.opacity(0.7))
                        .frame(width: 10, height: 10)
                    Text("Wasted")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            // Selected month details
            if let selected = selectedMonth {
                VStack(alignment: .leading, spacing: 8) {
                    Text(selected.month)
                        .font(.headline)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Saved")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(selected.savings, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.green)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing) {
                            Text("Wasted")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Text("$\(selected.waste, specifier: "%.0f")")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.red)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(12)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateChart = true
            }
        }
    }
}

// Progress Ring Component
struct ProgressRing: View {
    let progress: Double
    let color: Color
    let lineWidth: CGFloat = 8
    
    @State private var animatedProgress: Double = 0
    
    var body: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: lineWidth)
            
            // Progress ring
            Circle()
                .trim(from: 0, to: animatedProgress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeOut(duration: 1.0), value: animatedProgress)
        }
        .onAppear {
            animatedProgress = progress
        }
    }
}
