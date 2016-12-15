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
    var descripcion = "Relax"
    var porcentaje = 60
}

enum esfuerzo: Int {
    case relax = 50
    case slow = 60
    case medium = 70
    case fast = 80
    case heroe = 90
    case carefull = 100
}
