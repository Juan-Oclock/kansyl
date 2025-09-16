//
//  ModernLineChart.swift
//  kansyl
//
//  Modern, minimal line chart for displaying savings trends
//

import SwiftUI

struct ModernLineChart: View {
    let monthlyData: [MonthData]
    @State private var selectedIndex: Int? = nil
    @State private var animateChart = false
    @State private var showPoints = false
    
    private let lineWidth: CGFloat = 2.5
    private let dotSize: CGFloat = 8
    private let chartHeight: CGFloat = 200
    
    var maxValue: Double {
        monthlyData.map { $0.savings }.max() ?? 100
    }
    
    var minValue: Double {
        monthlyData.map { $0.savings }.min() ?? 0
    }
    
    var valueRange: Double {
        maxValue - minValue
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chart Area
            GeometryReader { geometry in
                ZStack {
                    // Grid lines
                    gridLines(in: geometry)
                    
                    // Gradient fill under the line
                    if animateChart {
                        fillArea(in: geometry)
                            .opacity(0.15)
                    }
                    
                    // Main line
                    if animateChart {
                        mainLine(in: geometry)
                            .stroke(
                                LinearGradient(
                                    colors: [Color(hex: "22C55E"), Color(hex: "16A34A")],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                ),
                                style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
                            )
                    }
                    
                    // Data points
                    if showPoints {
                        dataPoints(in: geometry)
                    }
                    
                    // Touch overlay for interaction
                    touchOverlay(in: geometry)
                }
            }
            .frame(height: chartHeight)
            
            // X-axis labels
            HStack(spacing: 0) {
                ForEach(Array(monthlyData.enumerated()), id: \.element.id) { index, data in
                    Text(data.month)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(
                            selectedIndex == index 
                                ? Design.Colors.buttonPrimary 
                                : Design.Colors.textTertiary
                        )
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.top, 12)
            
            // Selected value tooltip
            if let index = selectedIndex {
                selectedValueCard(for: monthlyData[index])
                    .transition(.asymmetric(
                        insertion: .scale(scale: 0.9).combined(with: .opacity),
                        removal: .scale(scale: 1.1).combined(with: .opacity)
                    ))
                    .padding(.top, 16)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                animateChart = true
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.6)) {
                showPoints = true
            }
        }
    }
    
    // MARK: - Helper Views
    
    private func gridLines(in geometry: GeometryProxy) -> some View {
        VStack(spacing: 0) {
            ForEach(0..<5) { i in
                if i > 0 {
                    Spacer()
                }
                Rectangle()
                    .fill(Design.Colors.border.opacity(0.3))
                    .frame(height: 0.5)
            }
        }
        .frame(width: geometry.size.width, height: geometry.size.height)
    }
    
    private func fillArea(in geometry: GeometryProxy) -> some View {
        Path { path in
            let width = geometry.size.width
            let height = geometry.size.height
            let spacing = width / CGFloat(monthlyData.count - 1)
            
            // Start from bottom left
            path.move(to: CGPoint(x: 0, y: height))
            
            // Draw line to first point
            let firstY = height - normalizedHeight(for: monthlyData[0].savings, maxHeight: height)
            path.addLine(to: CGPoint(x: 0, y: firstY))
            
            // Draw curve through all points
            for index in 0..<monthlyData.count {
                let x = CGFloat(index) * spacing
                let y = height - normalizedHeight(for: monthlyData[index].savings, maxHeight: height)
                
                if index > 0 {
                    let prevX = CGFloat(index - 1) * spacing
                    let prevY = height - normalizedHeight(for: monthlyData[index - 1].savings, maxHeight: height)
                    let midX = (prevX + x) / 2
                    
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: midX, y: prevY),
                        control2: CGPoint(x: midX, y: y)
                    )
                }
            }
            
            // Close the path
            path.addLine(to: CGPoint(x: width, y: height))
            path.closeSubpath()
        }
        .fill(
            LinearGradient(
                colors: [
                    Color(hex: "22C55E").opacity(0.5),
                    Color(hex: "22C55E").opacity(0.0)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        )
    }
    
    private func mainLine(in geometry: GeometryProxy) -> Path {
        Path { path in
            let width = geometry.size.width
            let height = geometry.size.height
            let spacing = width / CGFloat(monthlyData.count - 1)
            
            for index in 0..<monthlyData.count {
                let x = CGFloat(index) * spacing
                let y = height - normalizedHeight(for: monthlyData[index].savings, maxHeight: height)
                
                if index == 0 {
                    path.move(to: CGPoint(x: x, y: y))
                } else {
                    let prevX = CGFloat(index - 1) * spacing
                    let prevY = height - normalizedHeight(for: monthlyData[index - 1].savings, maxHeight: height)
                    let midX = (prevX + x) / 2
                    
                    path.addCurve(
                        to: CGPoint(x: x, y: y),
                        control1: CGPoint(x: midX, y: prevY),
                        control2: CGPoint(x: midX, y: y)
                    )
                }
            }
        }
    }
    
    private func dataPoints(in geometry: GeometryProxy) -> some View {
        let width = geometry.size.width
        let height = geometry.size.height
        let spacing = width / CGFloat(monthlyData.count - 1)
        
        return ZStack {
            ForEach(Array(monthlyData.enumerated()), id: \.element.id) { index, data in
                let x = CGFloat(index) * spacing
                let y = height - normalizedHeight(for: data.savings, maxHeight: height)
                
                Circle()
                    .fill(Color.white)
                    .frame(width: dotSize, height: dotSize)
                    .overlay(
                        Circle()
                            .stroke(Color(hex: "22C55E"), lineWidth: 2.5)
                    )
                    .scaleEffect(selectedIndex == index ? 1.5 : 1.0)
                    .position(x: x, y: y)
                    .animation(.spring(response: 0.3, dampingFraction: 0.7), value: selectedIndex)
            }
        }
    }
    
    private func touchOverlay(in geometry: GeometryProxy) -> some View {
        // Touch area is split evenly among data points, no need for spacing calculation
        return HStack(spacing: 0) {
            ForEach(Array(monthlyData.enumerated()), id: \.element.id) { index, _ in
                Rectangle()
                    .fill(Color.clear)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if selectedIndex == index {
                                selectedIndex = nil
                            } else {
                                selectedIndex = index
                                HapticManager.shared.playSelection()
                            }
                        }
                    }
            }
        }
    }
    
    private func selectedValueCard(for data: MonthData) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(data.month)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Design.Colors.textSecondary)
                
                Text(SharedCurrencyFormatter.formatPrice(data.savings))
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(Design.Colors.textPrimary)
                
                if data.waste > 0 {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(Color(hex: "EF4444"))
                            .frame(width: 6, height: 6)
                        Text("Waste: \(SharedCurrencyFormatter.formatPrice(data.waste))")
                            .font(.system(size: 11, weight: .regular))
                            .foregroundColor(Design.Colors.textTertiary)
                    }
                }
            }
            
            Spacer()
            
            // Percentage change if not first month
            if let currentIndex = monthlyData.firstIndex(where: { $0.id == data.id }),
               currentIndex > 0 {
                let previousSavings = monthlyData[currentIndex - 1].savings
                let change = ((data.savings - previousSavings) / previousSavings) * 100
                let isPositive = change >= 0
                
                HStack(spacing: 4) {
                    Image(systemName: isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .medium))
                    Text("\(abs(Int(change)))%")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(isPositive ? Color(hex: "22C55E") : Color(hex: "EF4444"))
            }
        }
        .padding(16)
        .background(Design.Colors.surface)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.04), radius: 8, x: 0, y: 2)
    }
    
    // MARK: - Helper Methods
    
    private func normalizedHeight(for value: Double, maxHeight: CGFloat) -> CGFloat {
        guard valueRange > 0 else { return maxHeight / 2 }
        
        // Add some padding to avoid points being at the very top/bottom
        let paddedValue = (value - minValue) / valueRange
        let padding: CGFloat = 0.1
        return CGFloat(paddedValue) * (maxHeight * (1 - 2 * padding)) + (maxHeight * padding)
    }
}

// MARK: - Alternative Minimal Bar Chart
struct ModernBarChart: View {
    let monthlyData: [MonthData]
    @State private var selectedIndex: Int? = nil
    @State private var animateBars = false
    
    private let barSpacing: CGFloat = 8
    private let chartHeight: CGFloat = 200
    
    var maxValue: Double {
        monthlyData.map { $0.savings }.max() ?? 100
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Chart Area
            HStack(alignment: .bottom, spacing: barSpacing) {
                ForEach(Array(monthlyData.enumerated()), id: \.element.id) { index, data in
                    VStack(spacing: 0) {
                        Spacer()
                        
                        // Bar
                        RoundedRectangle(cornerRadius: 4)
                            .fill(
                                LinearGradient(
                                    colors: selectedIndex == index 
                                        ? [Color(hex: "22C55E"), Color(hex: "16A34A")]
                                        : [Color(hex: "22C55E").opacity(0.3), Color(hex: "16A34A").opacity(0.3)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .frame(height: animateBars ? normalizedHeight(for: data.savings) : 0)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7)
                                    .delay(Double(index) * 0.05),
                                value: animateBars
                            )
                        
                        // Month label
                        Text(data.month)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(
                                selectedIndex == index 
                                    ? Design.Colors.buttonPrimary 
                                    : Design.Colors.textTertiary
                            )
                            .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                            if selectedIndex == index {
                                selectedIndex = nil
                            } else {
                                selectedIndex = index
                                HapticManager.shared.playSelection()
                            }
                        }
                    }
                }
            }
            .frame(height: chartHeight + 30)
            
            // Selected value
            if let index = selectedIndex {
                HStack {
                    Text(monthlyData[index].month)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Design.Colors.textSecondary)
                    
                    Spacer()
                    
                    Text(SharedCurrencyFormatter.formatPrice(monthlyData[index].savings))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(Design.Colors.textPrimary)
                }
                .padding(.top, 12)
                .transition(.opacity)
            }
        }
        .onAppear {
            animateBars = true
        }
    }
    
    private func normalizedHeight(for value: Double) -> CGFloat {
        guard maxValue > 0 else { return 0 }
        return CGFloat(value / maxValue) * chartHeight
    }
}