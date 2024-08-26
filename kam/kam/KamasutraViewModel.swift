import SwiftUI
import HealthKit
import Foundation
import WidgetKit
import WatchConnectivity

class WCSessionManager: NSObject, WCSessionDelegate, ObservableObject {
    static let shared = WCSessionManager()
    var healthStore = HKHealthStore()

    public override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        // Handle any activation state changes
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    func sessionDidBecomeInactive(_ session: WCSession) {
        // Handle the session becoming inactive
        print("WCSession did become inactive")
    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        // Handle the session deactivation
        session.activate()
        print("WCSession did deactivate and reactivated")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        if let action = message["action"] as? String {
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: .didReceiveWatchMessage, object: nil, userInfo: ["action": action])
            }
        }
    }
    func sendHealthData(_ data: [String: Any]) {
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(data, replyHandler: nil) { error in
                print("Failed to send health data: \(error.localizedDescription)")
            }
        }
    }
    
    func startTrainingSession() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("Health data is not available on this device.")
            return
        }
        
        let workoutConfiguration = HKWorkoutConfiguration()
        workoutConfiguration.activityType = .mixedCardio
        workoutConfiguration.locationType = .indoor
        
        do {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .mixedCardio
            configuration.locationType = .indoor
            let workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
            
            
            session.startActivity(with: Date())
            print("Training session started")
        } catch {
            print("Failed to start training session: \(error.localizedDescription)")
        }
    }
    
}

extension Notification.Name {
    static let didReceiveWatchMessage = Notification.Name("didReceiveWatchMessage")
}

// HealthKit Manager Class
class HealthDataObserver: NSObject, ObservableObject {
    private let healthStore = HKHealthStore()
    
    override init() {
        super.init()
        setupObserverQueries()
    }
    
    
    // Set up observer queries
    private func setupObserverQueries() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        
        // Step Count Observer
        let stepObserverQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Observer Query failed with error: \(error.localizedDescription)")
                return
            }
            
            self?.fetchLatestStepCount()
            completionHandler()
        }
        
        // Heart Rate Observer
        let heartRateObserverQuery = HKObserverQuery(sampleType: heartRateType, predicate: nil) { [weak self] _, completionHandler, error in
            if let error = error {
                print("Observer Query failed with error: \(error.localizedDescription)")
                return
            }
            
            self?.fetchLatestHeartRate()
            completionHandler()
        }
        
        healthStore.execute(stepObserverQuery)
        healthStore.execute(heartRateObserverQuery)
    }
    
    // Fetch latest step count
    private func fetchLatestStepCount() {
        let stepType = HKObjectType.quantityType(forIdentifier: .stepCount)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: stepType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample], let sample = samples.first else {
                print("Failed to fetch step count: \(String(describing: error?.localizedDescription))")
                return
            }
            
            let stepCount = sample.quantity.doubleValue(for: HKUnit.count())
            print("Latest step count: \(stepCount)")
            
            // Optionally, post a notification or update your app's state
        }
        
        healthStore.execute(query)
    }
    
    // Fetch latest heart rate
    private func fetchLatestHeartRate() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, samples, error in
            guard let samples = samples as? [HKQuantitySample], let sample = samples.first else {
                print("Failed to fetch heart rate: \(String(describing: error?.localizedDescription))")
                return
            }
            
            let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            print("Latest heart rate: \(heartRate)")
            
            // Optionally, post a notification or update your app's state
        }
        
        healthStore.execute(query)
    }
}

