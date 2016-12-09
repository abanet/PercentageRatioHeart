//
//  Latido.swift
//  PercentageRatioHeart
//
//  Created by Alberto Banet on 5/12/16.
//  Copyright © 2016 Alberto Banet. All rights reserved.
//


import UIKit

struct Latido {
    var icono = ""
    var descripcion = "Rango Medio"
    var bpm = 80
    
    var duration: Double {
        return 60.0 / Double(bpm)
    }
    
}
