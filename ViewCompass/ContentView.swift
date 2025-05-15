//
//  ContentView.swift
//  StepCompassApp
//
//  Created by Luben Ivanchev on 2025/05/13.
//

import SwiftUI
import CoreMotion

struct ContentView: View {
    
    private let pedometer: CMPedometer = CMPedometer()
    private let motionManager: CMMotionManager = CMMotionManager()
    
    @StateObject private var compassManager = CompassManager()
    
    @State private var steps: Int?
    @State private var distance: Double?
    
    private var isPedometerAvailable: Bool {
        return CMPedometer.isPedometerEventTrackingAvailable() && CMPedometer.isDistanceAvailable() && CMPedometer.isStepCountingAvailable()
    }
    
    private func initializePedometer() {
        if isPedometerAvailable {
            guard let startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) else { return }
            
            pedometer.queryPedometerData(from: startDate, to: Date()) {(data, error) in
                
                guard let data = data, error == nil else { return }
                
                guard let pedometerDistance = data.distance else { return }
                
                steps = data.numberOfSteps.intValue
                distance = pedometerDistance.doubleValue
            }
        }
    }
    
    private func updateUI(data: CMPedometerData) {
        steps = data.numberOfSteps.intValue
        
        guard let pedometerDistance = data.distance else { return }
        
        let distanceInMeters = Measurement(value: pedometerDistance.doubleValue, unit: UnitLength.meters)
        
        distance = distanceInMeters.converted(to: .miles).value
        
    }
    
    var body: some View {
        VStack {
            Image(systemName: "person")
                .imageScale(.large)
                .foregroundStyle(.tint)
            
                .onAppear {
                    initializePedometer()
                }
            Text(steps != nil ? "Steps: \(steps!)" : "Step count unavailable.")
                .padding()
            
            Text(distance != nil ? String(format: "%.2f miles traveled", distance!) : "Distance unavailable.")
        }
        .padding()
        
        VStack {
            // Compass dial
            ZStack {
                Circle()
                    .stroke(lineWidth: 3)
                    .foregroundColor(.gray)
                    .frame(width: 300, height: 300)
                
                // Markings for cardinal directions
                ForEach(0..<36) { index in
                    let angle = Double(index) * 10.0
                    let isCardinal = angle.truncatingRemainder(dividingBy: 90) == 0
                    
                    Rectangle()
                        .fill(isCardinal ? Color.red : Color.gray)
                        .frame(width: 2, height: isCardinal ? 30 : 15)
                        .offset(y: -150)
                        .rotationEffect(.degrees(angle))
                }
                
                // Pointer
                Triangle()
                    .fill(Color.blue)
                    .frame(width: 20, height: 100)
                    .offset(y: -50)
                    .rotationEffect(.degrees(compassManager.heading))
            }
            .rotationEffect(.degrees(-compassManager.heading))
            
            // Digital display
            Text("\(Int(compassManager.heading))° \(compassManager.cardinalDirection)")
                .font(.system(size: 32, weight: .bold))
                .padding(.top, 40)
        }
        .padding()
    }
}

// Triangle shape for compass pointer
struct Triangle: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.closeSubpath()
        
        return path
    }
}

// Compass manager to handle location updates
class CompassManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private let locationManager = CLLocationManager()
    
    @Published var heading: Double = 0.0
    @Published var cardinalDirection: String = "N"
    
    override init() {
        super.init()
        setupLocationManager()
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        
        if CLLocationManager.headingAvailable() {
            locationManager.startUpdatingHeading()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        heading = newHeading.magneticHeading
        cardinalDirection = directionFromHeading(newHeading.magneticHeading)
    }
    
    private func directionFromHeading(_ heading: Double) -> String {
        switch heading {
        case 0..<22.5: return "N"
        case 22.5..<67.5: return "NE"
        case 67.5..<112.5: return "E"
        case 112.5..<157.5: return "SE"
        case 157.5..<202.5: return "S"
        case 202.5..<247.5: return "SW"
        case 247.5..<292.5: return "W"
        case 292.5..<337.5: return "NW"
        default: return "N"
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Compass error: \(error.localizedDescription)")
    }
}

#Preview {
    ContentView()
}
