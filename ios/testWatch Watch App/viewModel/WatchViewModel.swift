import SwiftUI
import WatchConnectivity
import HealthKit
import WatchKit

class WatchViewModel:NSObject, ObservableObject,HKWorkoutSessionDelegate,HKLiveWorkoutBuilderDelegate {
    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        print("workoutSession>>didChangeTo \(toState)")
        
        // Wait for the session to transition states before ending the builder.
        if toState == .ended {
            builder?.endCollection(withEnd: date) { (success, error) in
                self.builder?.finishWorkout { (workout, error) in
                    
                }
            }
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("workoutSession>>didFailWithError \(error)")
    }
    
  
//    WKInterfaceController, HKWorkoutSessionDelegate,
    func workoutBuilder(_ workoutBuilder: HKLiveWorkoutBuilder, didCollectDataOf collectedTypes: Set<HKSampleType>) {
        for type in collectedTypes {
            if type == HKQuantityType.quantityType(forIdentifier: .heartRate)! {
                       // Handle heart rate data
                if let statistics = workoutBuilder.statistics(for: type as! HKQuantityType) {
                           let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
                           let value = statistics.mostRecentQuantity()?.doubleValue(for: heartRateUnit) ?? 0
                    counter = Int(value)
                    sendDataMessage(for: .sendHRToFlutter, data: ["counter": counter])
                           print("Workout Heart Rate: \(value) BPM")
                           // You can update UI or perform other actions with the heart rate data
                       }
                   }
                   // Handle other collected data types if needed
               }
    }
    
    func workoutBuilderDidCollectEvent(_ workoutBuilder: HKLiveWorkoutBuilder) {
        //if workoutBuilder.workoutEvents.count > 0{
            let workoutEvents = workoutBuilder.workoutEvents
            for event in workoutEvents {
                print("Work Builder Collect Data : ",event)
            }
            
        //}
    }

    var session: WCSession
    let healthStore = HKHealthStore()
    var builder: HKLiveWorkoutBuilder?
    var workOutSession: HKWorkoutSession?
    let queue = OperationQueue()
    

    @Published var counter = 0

    // Start the workout.
    func startWorkout(workoutType: HKWorkoutActivityType) {
        let configuration = HKWorkoutConfiguration()
        configuration.activityType = workoutType
        configuration.locationType = .indoor

        // Create the session and obtain the workout builder.
        do {
            workOutSession = try HKWorkoutSession(healthStore: healthStore, configuration: configuration)
            builder = workOutSession?.associatedWorkoutBuilder()
          
            builder?.delegate = self
            builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                                            workoutConfiguration: configuration)
                       
                       // Start the workout session
            workOutSession?.startActivity(with: Date())
        } catch {
            // Handle any exceptions.
            print("Error starting workout session: \(error.localizedDescription)")
            return
        }

        // Setup session and builder.

        builder?.delegate = self

        // Set the workout builder's data source.
        builder?.dataSource = HKLiveWorkoutDataSource(healthStore: healthStore,
                                                     workoutConfiguration: configuration)

        // Start the workout session and begin data collection.
        let startDate = Date()
        workOutSession?.startActivity(with: startDate)
        builder?.beginCollection(withStart: startDate) { (success, error) in
            // The workout has started.
            print("beginCollection :", success)
        }
    }
    
    
    // Add more cases if you have more receive method
    enum WatchReceiveMethod: String {
        case sendHRToNative
    }
    
    // Add more cases if you have more sending method
    enum WatchSendMethod: String {
        case sendHRToFlutter
    }
    
    init(session: WCSession = .default) {
        self.session = session

        super.init()
        self.session.delegate = self
        session.activate()
        requestAuthorization()
        
    }
    

    
    func sendDataMessage(for method: WatchSendMethod, data: [String: Any] = [:]) {
        sendMessage(for: method.rawValue, data: data)
    }
    
    // Request authorization to access HealthKit.
    func requestAuthorization() {
        // The quantity type to write to the health store.
        let typesToShare: Set = [
            HKQuantityType.workoutType()
        ]

        // The quantity types to read from the health store.
        let typesToRead: Set = [
            HKQuantityType.quantityType(forIdentifier: .heartRate)!,
            HKObjectType.activitySummaryType()
        ]

        // Request authorization for those quantity types.
        healthStore.requestAuthorization(toShare: typesToShare, read: typesToRead) { [self] (success, error) in
            print(success)
            print(error ?? "No Error")
            print(self.dataTypesToRead())
            var dataType : HKSampleType?
            dataType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!
            print("readHealthKitData : ", self.readHealthKitData(type:  dataType!))
         
            // Serial queue for sample handling and calculations.
            queue.maxConcurrentOperationCount = 1
            queue.name = "MotionManagerQueue"
      
            
            startWorkout(workoutType: .running)
            
        }
        
        
    }
    
    private func queryForUpdates(type: HKObjectType) {
         switch type {
         case HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!:
             debugPrint("HKQuantityTypeIdentifierHeartRate")
    
         default: debugPrint("Unhandled HKObjectType: \(type)")
         }
     }
    
    private func dataTypesToRead() -> Set<HKSampleType> {
          return Set(arrayLiteral:
                      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                     HKObjectType.workoutType()
          )
      }
      
      /// Types of data that this app wishes to write to HealthKit.
      ///
      /// - returns: A set of HKSampleType.
      private func dataTypesToWrite() -> Set<HKSampleType> {
          return Set(arrayLiteral:
                      HKObjectType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate)!,
                     HKObjectType.workoutType()
          )
      }
    
    
    func readHealthKitData(type : HKSampleType) {
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { (query, results, error) in
              if let error = error {
                  // Handle query error
                  print("Error querying heart rate: \(error.localizedDescription)")
                  return
              }

              if let heartRateSample = results?.first as? HKQuantitySample {
                  // Access heart rate value
                  let heartRate = heartRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
//                  counter = heartRate
                  self.counter = Int(heartRate)
                  self.sendDataMessage(for: .sendHRToFlutter, data: ["counter": self.counter])
                         print("Heart Rate self.counter: \(self.counter) BPM")
                         // You can update UI or perform other actions with the heart rate data
                     
                  print("Heart Rate Query: \(heartRate)")
              }
          }
        
        healthStore.execute(query)
    }
    
    
}

extension WatchViewModel: WCSessionDelegate {
    
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        
    }
    
    // Receive message From AppDelegate.swift that send from iOS devices
    func session(_ session: WCSession, didReceiveMessage message: [String : Any],replyHandler: @escaping ([String : Any]) -> Void) {
        DispatchQueue.main.async {
            guard let method = message["method"] as? String, let enumMethod = WatchReceiveMethod(rawValue: method) else {
                return
            }
            
            switch enumMethod {
            case .sendHRToNative:
                self.counter = (message["data"] as? Int) ?? 0
            }
        }
    }
    
    func sendMessage(for method: String, data: [String: Any] = [:]) {
        guard session.isReachable else {
            return
        }
        let messageData: [String: Any] = ["method": method, "data": data]
        session.sendMessage(messageData, replyHandler: nil, errorHandler: nil)
    }
    
}
