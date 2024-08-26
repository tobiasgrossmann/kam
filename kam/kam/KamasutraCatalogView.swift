import SwiftUI
import HealthKit
import Foundation
import HealthKit
import WidgetKit
import WatchConnectivity

struct KamasutraCatalogView: View {
    @ObservedObject var workoutManager = WorkoutManager()

    var healthStore = HKHealthStore()
    var heartRateQuantity = HKUnit(from: "count/min")
    //@State private var workoutState: HKWorkoutSessionState = .notStarted
    //@State private var workoutSession: HKWorkoutSession?
    @State private var workoutStartDate: Date?
    //@State private var workoutBuilder : HKWorkoutBuilder?

    // @State private var currentHeartRate: Double = 0.0
    // @State private var caloriesBurned: Double = 0.0

    @State private var activeMinutes: Double = 0.0
    
    @State private var selectedPosition: KamasutraPosition?
    // @State private var workoutManager.isTrainingStarted = false
    @State private var searchText = ""
    @State private var updatetimer = Timer.publish(every: 2.0, on: .main, in: .common).autoconnect()

    @State var standRingProgress: Double = 0.0
    @State var exerciseRingProgress : Double = 0.0
    @State var moveRingProgress: Double = 0.0
    
    
    init() {
      requestAuthorization()
        

    }
  
    func requestAuthorization() {
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
        healthStore.requestAuthorization(toShare: writeDataTypes, read: readDataTypes) { success, _ in
            if !success {
                print("did not got access to health data")
            } else {
                print("got access to health data")
            }
        }
    }
    
   
    private let positions = KamasutraModel.positions
    // private let healthManager = HealthManager()
        
    private var filteredPositions: [KamasutraPosition] {
        searchText.isEmpty ?
            positions :
            positions.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
    }
        
    var body: some View {
        NavigationView {
            ZStack {
                VStack {     
                    if let position = selectedPosition {
                        selectedPositionView(for: position)
                    } else {
                        searchBar
                        catalogList
                    }
                }
            }
            .navigationBarTitle("Passion Fit", displayMode: .inline)
            .background(Color.black)
            .foregroundColor(.white)
        } .onReceive(updatetimer) { _ in
            updateWorkoutData()
        }
        .preferredColorScheme(.dark)
    }
    
    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.gray)
                .padding(.leading, 8)
            
            TextField("Search...", text: $searchText)
                .textFieldStyle(PlainTextFieldStyle())
                .padding(10)
                .background(Color(UIColor.systemBackground))
                .cornerRadius(8)
                .padding(.horizontal)
        }
        .padding(.top)
    }
    
    private func selectedPositionView(for position: KamasutraPosition) -> some View {
        VStack(alignment: .leading) {
            healthRingsView
            positionImageView(for: position)
            positionNameView(for: position)
            positionDescriptionView(for: position) // Add this line
            trainingStatsView
            HStack {
                Spacer() // This pushes the buttons to the right
                trainingControlButtons
            }
        }
        .padding()
        .gesture(
            DragGesture()
                .onEnded { value in
                    if value.translation.width > 100 {
                        stopTraining()
                    }
                    selectedPosition = nil
                }
        )
        .onDisappear {
            if workoutManager.isTrainingStarted {
                updatetimer.upstream.connect().cancel()

                stopTraining()
            }
        }
    }
    private func positionDescriptionView(for position: KamasutraPosition) -> some View {
        Text(position.explanation)
            .font(.subheadline)
            .foregroundColor(.gray)
            .multilineTextAlignment(.leading)
            .lineLimit(nil) // Allows the text to use multiple lines as needed
            .frame(minHeight: 40, alignment: .leading) // Ensures a minimum height, alignment to the top-left
            .fixedSize(horizontal: false, vertical: true) // Prevents text from shrinking to fit
            .padding(.vertical, 5)
    }
    

    
    private var stopwatchView: some View {
        Text(formatElapsedTime(workoutManager.elapsedTime))
            .font(.system(size: 48, weight: .bold, design: .monospaced))
            .foregroundColor(.white)
            .padding()
            .background(Color.black.opacity(0.7))
            .cornerRadius(10)
    }
    
    private var healthRingsView: some View {
        HStack {
            Spacer()
            HealthRingsView(moveProgress: moveRingProgress, exerciseProgress: exerciseRingProgress, standProgress: standRingProgress)
                .frame(width: 50, height: 50)
                .foregroundColor(.white)
                .font(.caption)
        }
        .padding()
    }
    
    private func positionImageView(for position: KamasutraPosition) -> some View {
        Image(position.imageName)
            .resizable()
            .scaledToFit()
            .frame(height: UIScreen.main.bounds.height * 0.20)
            .background(Color.black.opacity(0.2))
            .cornerRadius(10)
    }
    
    private func positionNameView(for position: KamasutraPosition) -> some View {
        Text(position.name)
            .font(.largeTitle)
            .foregroundColor(.white)
            .padding(.vertical)
    }
    
    private var trainingStatsView: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(formatElapsedTime(workoutManager.elapsedTime)) // Replace this with your actual timer string variable
                .font(.system(size: 48, weight: .bold, design: .default))
                .foregroundColor(.white)
            if workoutManager.heartrate > 0 {
                  HStack {
                      Text("\(Int(workoutManager.heartrate))")
                          .font(.system(size: 36, weight: .regular, design: .default))
                          .foregroundColor(.white)
                      Image(systemName: "heart.fill")
                          .foregroundColor(.red)
                          .font(.system(size: 36))
                  }
              }
              if workoutManager.calories > 0 {
                  HStack {
                      Text("\(Int(workoutManager.calories))")
                          .font(.system(size: 36, weight: .regular, design: .default))
                          .foregroundColor(.red)
                      Text("CAL")
                          .font(.system(size: 24, weight: .bold, design: .default))
                          .foregroundColor(.red)
                  }
              }
        }
        .padding(.bottom)
    }
        
    private func formatElapsedTime(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private var trainingControlButtons: some View {
        HStack {
            Button(action: {
                if workoutManager.isTrainingStarted {
                    stopTraining()
                    selectedPosition = nil
                } else {
                    startTraining()
                }
            }) {
                Text(workoutManager.isTrainingStarted ? "Stop" : "Start")
                    .font(.headline)
                    .frame(width: 80, height: 80)
                    .background(workoutManager.isTrainingStarted ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .clipShape(Circle())
                    .shadow(color: .white.opacity(0.3), radius: 10, x: -5, y: -5)
                    .shadow(color: .gray.opacity(0.5), radius: 10, x: 5, y: 5)
                    .padding()
                    .padding(.bottom, 20)
            }
        }
    }
    
    private var catalogList: some View {
        List(filteredPositions) { position in
            Button(action: { selectedPosition = position }) {
                HStack {
                    Image(position.imageName)
                        .resizable()
                        .frame(width: 50, height: 50)
                        .clipShape(Circle())
                    Text(position.name)
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
        }
        .listStyle(PlainListStyle())
        .background(Color.black)
    }
    
   
    private func startTraining() {
        guard let position = selectedPosition else { return }
        workoutManager.isTrainingStarted = true
        print("Training started for position: \(position.name)")
        workoutStartDate = Date()
        let positionName = NSLocalizedString(position.name,comment:"")

        workoutManager.startTraining(for: positionName)
        


        
    }
    
    private func stopTraining() {
        workoutManager.isTrainingStarted = false
        print("Training stopped.")
        workoutManager.stopTraining()
        print("Workout ended!")
    }
    
    
    private func updateWorkoutData() {
        // Start heart rate monitoring
        // startHeartRateQuery()
        // Start active energy burned monitoring
        // startCalorieQuery()
        // Start active summary monitoring
        startActiveSummary()
    }
    
 
    /*
    func startHeartRateQuery() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let query = HKObserverQuery(sampleType: heartRateType, predicate: nil) { query, completionHandler, error in
            if error != nil {
                print("Observer query failed")
                return
            }
            self.fetchLatestHeartRateSample() // Fetch the latest heart rate
            completionHandler() // Call the completion handler after processing the query
        }
        healthStore.execute(query)
    }
    private func fetchLatestHeartRateSample() {
        let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { query, results, error in
            guard let sample = results?.first as? HKQuantitySample else {
                print("No heart rate samples available")
                DispatchQueue.main.async {
                    self.currentHeartRate = 0.0 // Set to 0 if no data
                }
                return
            }

            let sampleTime = sample.startDate.timeIntervalSinceNow
            if abs(sampleTime) > 3 {
                // If the sample is older than 3 seconds, set heart rate to 0
                print("Heart rate data is older than 3 seconds, setting to 0")
                DispatchQueue.main.async {
                    self.currentHeartRate = 0.0
                }
            } else {
                let heartRateUnit = HKUnit(from: "count/min")
                DispatchQueue.main.async {
                    self.currentHeartRate = sample.quantity.doubleValue(for: heartRateUnit)
                    print("Current heart rate: \(self.currentHeartRate)")
                }
            }
        }
        healthStore.execute(query)
    }
    

    func startCalorieQuery() {
        guard let workoutStartDate = workoutStartDate else { return }
        
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        // Predicate to filter samples from the workout start date onwards
        let predicate = HKQuery.predicateForSamples(withStart: workoutStartDate, end: nil, options: .strictStartDate)
        
        let query = HKObserverQuery(sampleType: energyType, predicate: predicate) { query, completionHandler, error in
            if error != nil {
                print("Observer query failed: \(String(describing: error))")
                return
            }
            
            self.fetchLatestCalorieSamples(from: workoutStartDate)
            completionHandler() // Call this to acknowledge the observer query
        }
        
        healthStore.execute(query)
    }

    private func fetchLatestCalorieSamples(from startDate: Date) {
        let energyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: nil, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: energyType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { query, results, error in
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
            }
        }
        
        healthStore.execute(query)
    }
    */
    
    private func startActiveSummary() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let tomorrow = calendar.date(byAdding: .day, value: 1, to: today)!
        // Create a predicate that filters for today only
        let predicate = HKQuery.predicateForSamples(withStart: today, end: tomorrow, options: .strictStartDate)
        // Use the predicate in the query to fetch only today's activity summary
        let query = HKActivitySummaryQuery(predicate: predicate) { [self] (query, summaries, error) in
            if let error = error {
                print("Error in query: \(error.localizedDescription)")
                return
            }
            guard let summaries = summaries, let activitySummary = summaries.first else {
                print("No data available or summaries are nil.")
                return
            }
            DispatchQueue.main.async {
                self.updateRings(with: activitySummary)
            }
        }
        // Execute the query
        healthStore.execute(query)
    }
    
    func updateRings(with summary: HKActivitySummary) {
        let moveGoal = summary.activeEnergyBurnedGoal.doubleValue(for: .kilocalorie())
        let exerciseGoal = summary.appleExerciseTimeGoal.doubleValue(for: .minute())
        let standGoal = summary.appleStandHoursGoal.doubleValue(for: .count())
        
        guard moveGoal >= 0, exerciseGoal >= 0, standGoal >= 0 else {
            print("One or more goals are zero or invalid.")
            return
        }
        
        if moveGoal > 0 {
            moveRingProgress = summary.activeEnergyBurned.doubleValue(for: .kilocalorie()) / moveGoal
        } else {
            // If the move goal is 0, consider if any energy was burned
            moveRingProgress = summary.activeEnergyBurned.doubleValue(for: .kilocalorie()) > 0 ? 1.0 : 0.0
        }

        if exerciseGoal > 0 {
            exerciseRingProgress = summary.appleExerciseTime.doubleValue(for: .minute()) / exerciseGoal
        } else {
            // If the exercise goal is 0, consider if any exercise time was recorded
            exerciseRingProgress = summary.appleExerciseTime.doubleValue(for: .minute()) > 0 ? 1.0 : 0.0
        }
        if standGoal > 0 {
            standRingProgress = summary.appleStandHours.doubleValue(for: .count()) / standGoal
        } else {
            // If the stand goal is 0, consider if any stand hours were recorded
            standRingProgress = summary.appleStandHours.doubleValue(for: .count()) > 0 ? 1.0 : 0.0
        }

        // Update UI with these progress values
        print("Move Ring Progress: \(moveRingProgress)")
        print("Exercise Ring Progress: \(exerciseRingProgress)")
        print("Stand Ring Progress: \(standRingProgress)")
    }
    

    

}

struct KamasutraCatalogView_Previews: PreviewProvider {
    static var previews: some View {
        KamasutraCatalogView()
    }
}



