import Foundation
import HealthKit
import WatchConnectivity

@available(iOS 17.0, *)
class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate {
    
    @Published var workoutState: HKWorkoutSessionState = .notStarted
    @Published var workoutSession: HKWorkoutSession?
    @Published var workoutBuilder : HKWorkoutBuilder?
    @Published var healthStore = HKHealthStore()

    func sessionDidBecomeInactive(_ session: WCSession) {
        print("Error starting workout: sessionDidBecomeInactive")

    }
    
    func sessionDidDeactivate(_ session: WCSession) {
        print("Error starting workout: sessionDidDeactivate")
    }
    
    @Published var isTrainingStarted = false

    @Published var timer: Timer?
    @Published  var workoutStartDate: Date?
    @Published  var elapsedTime = 0
    @Published var heartrate :Double = 0.0
    @Published var calories :Double = 0.0
    private var position : String = ""
    override init() {
        super.init()
        setupWatchConnectivity()
    }
    
    private func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }
    
    func startTraining(for position: String) {
        self.position = position
        isTrainingStarted = true
        elapsedTime = 0 // Reset elapsed time
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.elapsedTime += 1
        }
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["workoutStarted": true], replyHandler: nil) { error in
                print("Error sending message to watch: \(error.localizedDescription)")
            }
            WCSession.default.sendMessage(["workoutPosition": position], replyHandler: nil) { error in
                print("Error sending message to watch: \(error.localizedDescription)")
            }
        } else {
            let configuration = HKWorkoutConfiguration()
            configuration.activityType = .mixedCardio
            configuration.locationType = .indoor
            workoutBuilder = HKWorkoutBuilder(healthStore: healthStore, configuration: configuration, device: .local())
            workoutBuilder!.beginCollection(withStart: Date()) { (success, error) in
                if let error = error {
                    print("Error starting workout: \(error.localizedDescription)")
                    return
                }
                print("Workout started!")
            }
        }
    }
    
    func stopTraining() {
        isTrainingStarted = false
        timer?.invalidate()
        elapsedTime = 0 // Reset elapsed time
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["workoutStop": true], replyHandler: nil) { error in
                print("Error sending message to watch: \(error.localizedDescription)")
            }
        } else {
            
            guard let workoutbuild = workoutBuilder else { return }
            workoutbuild.endCollection(withEnd: Date()) { (success, error) in
                if let error = error {
                    // Handle errors here
                    print("Error ending workout: \(error.localizedDescription)")
                    return
                }
                workoutbuild.finishWorkout { (workout, error) in
                    if let error = error {
                        // Handle errors here
                        print("Error finishing workout: \(error.localizedDescription)")
                        return
                    }
                    if let workout = workout {
                        let newWorkout = HKWorkout(activityType: .mixedCardio,
                                                   start: self.workoutStartDate!,
                                                   end: workout.endDate,
                                                   duration: workout.duration,
                                                   totalEnergyBurned: workout.totalEnergyBurned,
                                                   totalDistance: nil,
                                                   device: HKDevice.local(),
                                                   metadata: ["passionfit": self.position])
                        
                        
                        self.healthStore.save(newWorkout, withCompletion: { (success, error) in
                            if let error = error {
                                // Handle errors here
                                print("Error saving workout: \(error.localizedDescription)")
                                return
                            } else {
                                print("Saving workout: \(success)")
                                
                            }
                        })
                    }
                }
            }
        }
    }
    
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let workoutStopped = message["workoutStopped"] as? Bool, workoutStopped {
            DispatchQueue.main.async {
                self.stopTraining()
            }
        }
        if let calories = message["calories"] as? Double {
            // Set the calories value in your app
            self.calories = calories
        }
        
        if let heartrate = message["heartrate"] as? Double {
            // Set the heartrate value in your app
            self.heartrate = heartrate
        }
        
        
    }
    

}
