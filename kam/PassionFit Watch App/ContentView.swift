import SwiftUI
import WatchConnectivity
import HealthKit

class WorkoutManager: NSObject, ObservableObject, WCSessionDelegate, HKWorkoutSessionDelegate, HKLiveWorkoutBuilderDelegate {
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            if type == HKObjectType.quantityType(forIdentifier: .heartRate) {
                fetchLatestHeartRateSample()
            }
            if type == HKObjectType.quantityType(forIdentifier: .activeEnergyBurned) {
                fetchLatestCalorieSamples()
            }
        }
    }
    
    private var workoutStartDate: Date?

    @Published var isTrainingStarted = false
    @Published var elapsedTime = 0
    @Published var currentHeartRate: Double = 0.0
    @Published var caloriesBurned: Double = 0.0
    @Published var workoutPosition = ""

    private var timer: Timer?
    private var workoutSession: HKWorkoutSession?
    private var workoutBuilder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()

    override init() {
        super.init()
        setupWatchConnectivity()
        
        let readDataTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.restingHeartRate)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.biologicalSex)!,
            HKObjectType.characteristicType(forIdentifier: HKCharacteristicTypeIdentifier.dateOfBirth)!,
            HKObjectType.workoutType(),
            HKObjectType.activitySummaryType(),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
        ]

        let writeDataTypes: Set = [
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
            HKQuantityType.workoutType(),
            HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.activeEnergyBurned)!,
        ]
        healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { [weak self] success, _ in
            if !success {
                print("Did not get access to health data")
            } else {
                print("Got access to health data")
            }
        }
    }

    func setupWatchConnectivity() {
        if WCSession.isSupported() {
            let session = WCSession.default
            session.delegate = self
            session.activate()
        }
    }

    func startTraining() {
        guard !isTrainingStarted else { return }
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = .mixedCardio
        configuration.locationType = .indoor
        do {
            workoutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            workoutBuilder = workoutSession?.associatedWorkoutBuilder() as? HKLiveWorkoutBuilder
            workoutBuilder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore, workoutConfiguration: configuration)
            
            workoutSession?.delegate = self
            workoutBuilder?.delegate = self
            
            workoutSession?.startActivity(with: Date())
            workoutBuilder?.beginCollection(withStart: Date()) { [weak self] success, error in
                if !success {
                    print("Error starting workout collection: \(String(describing: error?.localizedDescription))")
                }
            }
            
            workoutStartDate = Date()
            isTrainingStarted = true
            startTimer()
            print("Training started on watch.")
            
            // Notify the iPhone that the workout has started
            if WCSession.default.isReachable {
                WCSession.default.sendMessage(["workoutStarted": true], replyHandler: nil) { error in
                    print("Error sending message to iPhone: \(error.localizedDescription)")
                }
            }
            
        } catch {
            print("Failed to start workout session: \(error.localizedDescription)")
        }
    }

    func stopTraining() {
        guard isTrainingStarted else { return }
        
        workoutSession?.end()
        workoutBuilder?.endCollection(withEnd: Date()) { [weak self] success, error in
            guard let self = self else { return }
            
            if !success {
                print("Error ending workout collection: \(String(describing: error?.localizedDescription))")
                return
            }
            
            self.workoutBuilder?.finishWorkout { (workout, error) in
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
                                               metadata: ["passionfit": self.workoutPosition])
                    
                    
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
        
        isTrainingStarted = false
        elapsedTime = 0
        timer?.invalidate()
        print("Training stopped on watch.")
        
        // Notify the iPhone that the workout has stopped
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(["workoutStopped": true], replyHandler: nil) { error in
                print("Error sending message to iPhone: \(error.localizedDescription)")
            }
        }
    }

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 5.0, repeats: true) { [weak self] _ in
            self?.fetchLatestHeartRateSample()
            self?.fetchLatestCalorieSamples()
            self?.updateElapsedTime()
        }
    }

    private func updateElapsedTime() {
        guard let workoutStartDate = workoutStartDate else { return }
        elapsedTime = Int(Date().timeIntervalSince(workoutStartDate))
    }

    private func fetchLatestHeartRateSample() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in
            guard let self = self else { return }
            guard let sample = results?.first as? HKQuantitySample else {
                print("No heart rate samples available")
                DispatchQueue.main.async {
                    self.currentHeartRate = 0.0 // Set to 0 if no data
                }
                return
            }

            let heartRateUnit = HKUnit(from: "count/min")
            DispatchQueue.main.async {
                self.currentHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(["heartrate": self.currentHeartRate], replyHandler: nil) { error in
                        print("Error sending message to iPhone: \(error.localizedDescription)")
                    }
                }
            }
        }
        healthStore.execute(query)
    }

    private func fetchLatestCalorieSamples() {
        guard let workoutStartDate = workoutStartDate else { return }
        
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { [weak self] query, results, error in
            guard let self = self else { return }
            guard let samples = results as? [HKQuantitySample] else {
                print("No calorie samples available")
                DispatchQueue.main.async {
                    self.caloriesBurned = 0.0 // Set to 0 if no data
                }
                return
            }
            
            var totalCaloriesBurnedDuringSession = 0.0
            
            for sample in samples {
                let energyUnit = HKUnit.kilocalorie()
                totalCaloriesBurnedDuringSession += sample.quantity.doubleValue(for: energyUnit)
            }
            
            DispatchQueue.main.async {
                self.caloriesBurned = totalCaloriesBurnedDuringSession
                print("Calories burned during this session: \(self.caloriesBurned)")
                if WCSession.default.isReachable {
                    WCSession.default.sendMessage(["calories": self.caloriesBurned], replyHandler: nil) { error in
                        print("Error sending message to iPhone: \(error.localizedDescription)")
                    }
                }
            }
        }
        
        healthStore.execute(query)
    }

    // WCSessionDelegate - Handle incoming messages
    func session(_ session: WCSession, didReceiveMessage message: [String : Any]) {
        if let workoutStarted = message["workoutStarted"] as? Bool, workoutStarted {
            DispatchQueue.main.async { [weak self] in
                self?.startTraining()
            }
        }
        if let workoutStop = message["workoutStop"] as? Bool, workoutStop {
            DispatchQueue.main.async { [weak self] in
                self?.stopTraining()
            }
        }
        if let workoutPosition = message["workoutPosition"] as? String {
            DispatchQueue.main.async { [weak self] in
                self?.workoutPosition = workoutPosition
            }
        }
    }

    // WCSessionDelegate methods
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            print("WCSession activation failed with error: \(error.localizedDescription)")
            return
        }
        print("WCSession activated with state: \(activationState.rawValue)")
    }
    
    #if os(iOS)
    func sessionDidBecomeInactive(_ session: WCSession) {}
    func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }
    #endif

    // HKWorkoutSessionDelegate methods
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout session failed with error: \(error.localizedDescription)")
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("Workout session state changed from \(fromState.rawValue) to \(toState.rawValue) at \(date)")
    }
    
    // HKLiveWorkoutBuilderDelegate methods
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        print("Workout builder did collect event")
    }
    
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf dataSource: HKLiveWorkoutDataSource) {
        print("Workout builder did collect data of data source")
    }
}

struct ContentView: View {
    @ObservedObject var workoutManager = WorkoutManager()

    var body: some View {
        VStack {
            if workoutManager.isTrainingStarted {
                Text(workoutManager.workoutPosition)
                    .font(.headline)
                    .padding()

                Button(action: {
                    workoutManager.stopTraining()
                }) {
                    Text("Stop")
                        .font(.headline)
                        .frame(width: 100, height: 100)
                        .background(Color.red)
                        .foregroundColor(.white)
                        .clipShape(Circle())
                }
                .padding(.top, 20)
            } else {
                Image(systemName: "hourglass")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
                    .padding()
            }
        }
    }
}

@main
struct PassionFit_Watch_AppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
