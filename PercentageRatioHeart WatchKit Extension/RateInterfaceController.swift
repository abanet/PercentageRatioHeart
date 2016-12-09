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

    @IBOutlet var porcentajeLatidos: WKInterfaceLabel!
    @IBOutlet var imgCorazon: WKInterfaceImage!
    @IBOutlet var txtLatidos: WKInterfaceLabel!
    
    var patronesPulsaciones = [
        Latido(icono:"❤️", descripcion: "Rápido", bpm: 160),
        Latido(icono:"💜", descripcion: "Medio", bpm: 140),
        Latido(icono:"💚", descripcion: "Lento", bpm: 120),
        Latido(icono:"💙", descripcion: "Muy relajado", bpm: 60),
        ]
    
    var workoutSession: HKWorkoutSession?
    var healthStore: HKHealthStore?
    let heartRateUnit = HKUnit(from: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    // esto se puede mejorar...

    var maxPulsaciones: Int = 170
    
    var timer: Timer?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
  
        // Recuperamos nuestro máximo de pulsaciones para mostrarlo en pantalla y realizar los cálculos necesarios.
    
        maxPulsaciones = UserDefaults.standard.integer(forKey: "pulsaciones")
        if maxPulsaciones != 0 {
            txtLatidos.setText("Your 100%: " + String(describing: maxPulsaciones))
        } else {
            // Nunca debería de llegar aquí
        }
        
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
        
           // iniciarTimer()
        } catch {
            print("error configurando la sessión de entrenamiento")
        }
    }
    
    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
        //pararTimer()
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
            self.txtLatidos.setText("\(UInt16(value))/\(self.maxPulsaciones)")
            let porcentaje = self.calcularPorcentaje(pulsaciones: value)
            self.porcentajeLatidos.setText(porcentaje)
            //self.animateHeart()
        }
    }

    func animateHeart() {
        print("animateHeart()")
        self.animate(withDuration: 0.5) {
        self.imgCorazon.setWidth(50)
        self.imgCorazon.setHeight(40)
    }
        
        let when = DispatchTime.now() + Double(Int64(0.1 * double_t(NSEC_PER_SEC))) / Double(NSEC_PER_SEC)
        print(when.rawValue)
        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        queue.asyncAfter(deadline: when) {
            DispatchQueue.main.async(execute: {
                self.animate(withDuration: 0.5, animations: {
                self.imgCorazon.setWidth(30)
                self.imgCorazon.setHeight(20)
                })
            })
        }
    }
    
    
    // Funciones del timer
    func iniciarTimer() {
        print("Iniciando timer")
        let aSelector : Selector = #selector(animateHeart)
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: aSelector, userInfo: nil, repeats: true)
        RunLoop.main.add(self.timer!, forMode: .commonModes)
    }
    
    func pararTimer() {
        print("Invalidando Timer")
        self.timer?.invalidate()
    }
    
    // Calculo del porcentaje 
    func calcularPorcentaje(pulsaciones: Double)->String{
        let porcentajeDouble = pulsaciones * 100 / Double(maxPulsaciones)
        return String(Int(porcentajeDouble)) + " %"
    }
    
    
}
