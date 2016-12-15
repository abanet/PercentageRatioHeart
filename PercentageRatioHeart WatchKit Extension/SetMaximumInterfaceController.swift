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
        } else {
            // la primera vez establecemos el valor 160 como valor de partida
            pulsaciones = 150
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
    
    @IBAction func decrementar5() {
        decrementar(5)
    }
    
    @IBAction func incrementar5() {
        incrementar(5)
    }
    
    @IBAction func incrementarUno() {
        incrementar(1)
    }
    
    @IBAction func decrementarUno() {
        decrementar(1)
    }

    func incrementar(_ cantidad: Int){
        pulsaciones = pulsaciones + cantidad
        if pulsaciones > MaximumRate.maxPulsaciones {
            pulsaciones = MaximumRate.maxPulsaciones // máximo permitido por la aplicación
        }
        UserDefaults.standard.set(pulsaciones, forKey:"pulsaciones")
    }
    
    func decrementar(_ cantidad: Int){
        pulsaciones = pulsaciones - cantidad
        if pulsaciones < MaximumRate.minPulsaciones {
            pulsaciones = MaximumRate.minPulsaciones
            
        }
        UserDefaults.standard.set(pulsaciones, forKey:"pulsaciones")

    }
}
