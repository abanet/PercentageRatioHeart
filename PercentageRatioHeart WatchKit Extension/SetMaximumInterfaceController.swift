//
//  SetMaximumInterfaceController.swift
//  PercentageRatioHeart
//
//  Created by Alberto Banet on 29/11/16.
//  Copyright © 2016 Alberto Banet. All rights reserved.
//

import WatchKit
import Foundation

struct MaximumRate {
    static let maxPulsaciones = 200
    static let minPulsaciones = 60
    static let incrementoPulsaciones = 5
}

class SetMaximumInterfaceController: WKInterfaceController {

    @IBOutlet var btnIncrementar: WKInterfaceButton!
    @IBOutlet var btnDecrementar: WKInterfaceButton!
    
    @IBOutlet var lblPulsaciones: WKInterfaceLabel!
    
    var pulsaciones: Int = 170 {
        didSet {
            lblPulsaciones.setText(String("\(pulsaciones)"))
        }
    }
    
    override func awake(withContext context: Any?) {
        super.awake(withContext: context)
        
        // Configure interface objects here.
        
        // Leemos las pulsaciones que tengamo guardadas
        let savedPulsaciones = UserDefaults.standard.integer(forKey: "pulsaciones")
        if savedPulsaciones != 0 { // Hay pulsaciones guardadas
            pulsaciones = savedPulsaciones
        }
        
    }

    override func willActivate() {
        // This method is called when watch view controller is about to be visible to user
        super.willActivate()
    }

    override func didDeactivate() {
        // This method is called when watch view controller is no longer visible
        super.didDeactivate()
    }

    
    // Funciones para incrementar y decrementar el máximo de pulsaciones. De 5 en 5.
    
    @IBAction func decrementar() {
        pulsaciones = pulsaciones - MaximumRate.incrementoPulsaciones
        if pulsaciones < MaximumRate.minPulsaciones {
            pulsaciones = MaximumRate.minPulsaciones
        }
    }
    
    @IBAction func incrementar() {
        pulsaciones = pulsaciones + MaximumRate.incrementoPulsaciones
        if pulsaciones > MaximumRate.maxPulsaciones {
            pulsaciones = MaximumRate.maxPulsaciones // máximo permitido por la aplicación
        }
    }
}
