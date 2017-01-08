//
//  main.swift
//  test
//
//  Created by quaerix on 08.01.17.
//  Copyright © 2017 quaerix. All rights reserved.
//

import Foundation

// инициализируем генератор
srandom(UInt32(time(nil)))

/// полигон построения клеточного поля и проверки нахлждения сквозного пути
func cellPolygon(dimension : Int, threshold : Double, fullway : Bool) {
   
   let poly = CellPolygon(dimension: dimension, threshold: threshold)
   // итоги
   if fullway {
      let ways = poly.crossAllPoints()
      
      poly.printCells(special: ways)
   }
   else {
      let field  = poly.field
      let cross  = poly.crossPoints()
      let enters = cross.reduce(Set<Int>()) { $0.union($1.0) }.map() { field.index(($0,0)) }
      let exits  = cross.reduce(Set<Int>()) { $0.union($1.1) }.map() { field.index(($0,field.height-1)) }
      
      poly.printCells(special: [Set(enters).union(Set(exits))])
   }
   print(poly.realThreshold)
}

//cellPolygon(dimension: 20, threshold: 0.62, fullway: false)
//_ = cellPolygonFindWays(dimension: 80, threshold: 0.55, ways_count: 2)

// фабрика
findProbabilitiesForCellFieldCrossWays(dimension: 100, ways_count: 2, max_iterations: 1_000, probability: 55...65)

// фабрика
// численно доказываем, что при пороге открытия 0.593 вероятность сквозной связности резко возрастает
//calcProbabilitiesForCellField(dimension: 100, iterations: 1000, probability: 50...70)
/*
 calc avg. probability of cross connection for open state threshold's range 50...70% with 1000 iterations for each, on cells field [100x100]

 48%	0.0% (23)
 49%	0.0% (502)
 50%	0.0% (991)
 51%	0.0% (995)
 52%	0.0% (980)
 53%	0.101010101010101% (990)
 54%	0.29296875% (1024)
 55%	1.70854271356784% (995)
 56%	3.8422649140546% (989)
 57%	14.3984220907298% (1014)
 58%	32.4214792299899% (987)
 59%	57.1288102261554% (1017)
 60%	78.150406504065% (984)
 61%	91.8604651162791% (1032)
 62%	97.4279835390947% (972)
 63%	99.2063492063492% (1008)
 64%	99.9002991026919% (1003)
 65%	99.8992950654582% (993)
 66%	100.0% (1008)
 67%	100.0% (982)
 68%	100.0% (1000)
 69%	100.0% (972)
 70%	100.0% (531)
 71%	100.0% (8)
 
 */
