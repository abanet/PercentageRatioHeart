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

enum PatronPulsacion: Int {
    case relax = 5
    case slow  = 4
    case medium = 3
    case fast = 2
    case heroe = 1
    case carefull = 0
}

class RateInterfaceController: WKInterfaceController, HKWorkoutSessionDelegate {

    @IBOutlet var pruebaCorazon: WKInterfaceLabel!
    @IBOutlet var porcentajeLatidos: WKInterfaceLabel!
    @IBOutlet var txtLatidos: WKInterfaceLabel!
    
    @IBOutlet var txtMaxToday: WKInterfaceLabel!
    
    var patronesPulsaciones = [
        Latido(icono:"💔", descripcion: "Be Carefull my friend", porcentaje: 100),
        Latido(icono:"❤️", descripcion: "Heroe!!!", porcentaje: 90),
        Latido(icono:"💛", descripcion: "Fast", porcentaje: 80),
        Latido(icono:"💜", descripcion: "Medium", porcentaje: 70),
        Latido(icono:"💚", descripcion: "Slow", porcentaje: 60),
        Latido(icono:"💙", descripcion: "Relax", porcentaje: 50),
        ]
    
    var workoutSession: HKWorkoutSession?
    var healthStore: HKHealthStore?
    let heartRateUnit = HKUnit(from: "count/min")
    var anchor = HKQueryAnchor(fromValue: Int(HKAnchoredObjectQueryNoAnchor))
    
    // esto se puede mejorar...

    var maxPulsaciones: Int = 170
    var maxPulsacionesToday: Int = 0
    
    var timer: Timer?
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
  
        // Recuperamos nuestro máximo de pulsaciones para mostrarlo en pantalla y realizar los cálculos necesarios.
    
        maxPulsaciones = UserDefaults.standard.integer(forKey: "pulsaciones")
        if maxPulsaciones != 0 {
            txtLatidos.setText("Your 100%: " + String(describing: maxPulsaciones))
        } else {
            // Nunca debería de llegar aquí
            // Alerta: avisar de que no se puede calcular el porcentaje y que debe configurar su máx. de pulsaciones.
            let accion = WKAlertAction(title: "Ok", style: .cancel, handler: {})
            self.presentAlert(withTitle: "Configuration Not Found!", message: "You should set your maximum heart reat in order to calculate your percentage", preferredStyle: .alert, actions: [accion])
        }
        
       // self.setTitle("Spinning Mataelpino")
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
        
        pruebaCorazon.setText(patronesPulsaciones[0].icono)
        
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
        print("workoutDidEnd") // a ver si está saliendo al cerrar la actividad...
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
            let porcentaje = self.calcularPorcentajeToString(pulsaciones: value)
            self.setColorCorazon(pulsaciones: value)
            self.actualizarMaxPulsacionesToday(pulsaciones: value)
            self.porcentajeLatidos.setText(porcentaje)
            
        }
    }

   
    func setColorCorazon(pulsaciones: Double){
        let pulsaciones = calcularPorcentajeToInt(pulsaciones: pulsaciones)
        
        guard pulsaciones > esfuerzo.relax.rawValue else {
            pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.relax.rawValue].icono)
            return
        }
   
        switch pulsaciones {
            case esfuerzo.relax.rawValue ..< esfuerzo.slow.rawValue:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.relax.rawValue].icono)
                print("relax")
            case esfuerzo.slow.rawValue ..< esfuerzo.medium.rawValue:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.slow.rawValue].icono)
                print("slow")
            case esfuerzo.medium.rawValue ..< esfuerzo.fast.rawValue:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.medium.rawValue].icono)
                print("medium")
            case esfuerzo.fast.rawValue ..< esfuerzo.heroe.rawValue:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.fast.rawValue].icono)
                print("fast")
            case esfuerzo.heroe.rawValue ..< esfuerzo.carefull.rawValue:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.heroe.rawValue].icono)
                print("heroe")
            default:
                pruebaCorazon.setText(patronesPulsaciones[PatronPulsacion.carefull.rawValue].icono)
                print("carefull")
        }
    }
    
    // Opciones del menú para finalizar la actividad
    @IBAction func finalizarActividad() {
        // Terminar sesión de trabajo
        healthStore?.end(workoutSession!)
        self.dismiss()
        // TODO: mostrar anillo?
    }
    
    @IBAction func cancelarFinalizacion() {
        // No hacemos nada. La actividad continua
    }
    
    
    
    
    func calcularPorcentajeToInt(pulsaciones: Double)->Int{
        guard maxPulsaciones > 0 else {
            print("el máximo de pulsaciones es 0. Imposible calcular porcentaje")
            return 0
        }
        let porcentajeDouble = pulsaciones * 100 / Double(maxPulsaciones)
        return Int(porcentajeDouble)
    }
    
    // Calculo del porcentaje 
    func calcularPorcentajeToString(pulsaciones: Double)->String{
        guard maxPulsaciones > 0 else {
            print("el máximo de pulsaciones es 0. Imposible calcular porcentaje")
            return "--"
        }
        return String(calcularPorcentajeToInt(pulsaciones: pulsaciones)) + " %"
    }
    

    
    // Actualizar el máximo de las pulsaciones en el workout actual
    func actualizarMaxPulsacionesToday(pulsaciones: Double){
        if Int(pulsaciones) > maxPulsacionesToday {
            maxPulsacionesToday = Int(pulsaciones)
            let porcentajeMax = calcularPorcentajeToString(pulsaciones: Double(maxPulsacionesToday))
            txtMaxToday.setText("Max. today: \(maxPulsacionesToday) / \(porcentajeMax)%")
        }
    }
}
