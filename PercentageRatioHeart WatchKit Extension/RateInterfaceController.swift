//
//  RateInterfaceController.swift
//  PercentageRatioHeart
//
//  Created by Alberto Banet on 29/11/16.
//  Copyright © 2016 Alberto Banet. All rights reserved.
//

import WatchKit
import Foundation
import HealthKit


class RateInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    var workoutSession: HKWorkoutSession?
    var healthStore: HKHealthStore?
    let heartRateUnit = HKUnit(from: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
  
    }

    override func willActivate() {
        super.willActivate()
        
        healthStore = HKHealthStore()
        
        guard HKHealthStore.isHealthDataAvailable() == true else {
            print("not available.")
            return
        }
        
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: HKQuantityTypeIdentifier.heartRate) else {
            print("no permitido.")
            return
        }
        
        let dataTypes = Set(arrayLiteral: quantityType)
        healthStore?.requestAuthorization(toShare: nil, read: dataTypes) { (success, error) -> Void in
            if success == false {
                print("no autorización: \(error)")
            } else {
                self.startWorkout()
            }
        }
    }

    func startWorkout() {
        // Create a new workout session
        let configuracionActividad = HKWorkoutConfiguration()
        configuracionActividad.activityType = .cycling
        configuracionActividad.locationType = .indoor
        do {
            self.workoutSession = try HKWorkoutSession(configuration: configuracionActividad)
            self.workoutSession!.delegate = self;
            // Start the workout session
            healthStore?.start(self.workoutSession!)
        } catch {
            print("error configurando la sessión de entrenamiento")
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    func workoutSession(_ workoutSession: HKWorkoutSession, didChangeTo toState: HKWorkoutSessionState, from fromState: HKWorkoutSessionState, date: Date) {
        switch toState {
        case .running:
            workoutDidStart(date)
        case .ended:
            workoutDidEnd(date)
        default:
            print("Estado no esperado: \(toState)")
        }
    }
    
    func workoutSession(_ workoutSession: HKWorkoutSession, didFailWithError error: Error) {
        print("Workout error: \(error._userInfo)")
    }
    
    func workoutDidStart(_ date: Date) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore?.execute(query)
        } else {
            print("no puedo empezar")
        }
    }
    
    func workoutDidEnd(_ date: Date) {
        if let query = createHeartRateStreamingQuery(date) {
            healthStore?.stop(query)
        } else {
            print("no puedo parar")
        }
    }
    
    func createHeartRateStreamingQuery(_ workoutStartDate: Date) -> HKQuery? {
        guard let quantityType = HKObjectType.quantityType(forIdentifier: .heartRate)
            else { return nil }
        
        let heartRateQuery = HKAnchoredObjectQuery(type: quantityType, predicate: nil, anchor: anchor, limit: Int(HKObjectQueryNoLimit)) {
            (query, sampleObjects, deletedObjects, newAnchor, error) -> Void in
            guard let newAnchor = newAnchor else { return }
            self.anchor = newAnchor
            self.updateHeartRate(sampleObjects)
            
        }
        
        heartRateQuery.updateHandler = {(query, samples, deleteObjects, newAnchor, error) -> Void in
            self.anchor = newAnchor!
            self.updateHeartRate(samples)
        }
        return heartRateQuery
    }
    
    
    func updateHeartRate(_ samples: [HKSample]?) {
        guard let heartRateSamples = samples as? [HKQuantitySample] else {return}
        
        DispatchQueue.main.async {
            guard let sample = heartRateSamples.first else{return}
            let value = sample.quantity.doubleValue(for: self.heartRateUnit)
            print(String(UInt16(value)))
            
            // retrieve source from sample
            let name = sample.sourceRevision.source.name
            
            
            //self.animateHeart()
        }
    }

    func animateHeart() {
        self.animate(withDuration: 0.5) {
         //   self.heart.setWidth(60)
           // self.heart.setHeight(90)
        }
        
        let when = DispatchTime.now() + Double(Int64(0.5 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        queue.asyncAfter(deadline: when) {
            DispatchQueue.main.async(execute: {
                self.animate(withDuration: 0.5, animations: {
                   // self.heart.setWidth(50)
                    //self.heart.setHeight(80)
                })
            })
        }
    }
}
