//
//  cellpolygon.swift
//  QuickUnion
//
//  Created by quaerix on 08.01.17.
//  Copyright © 2017 quaerix. All rights reserved.
//

import Foundation

/// Полигон проверки теории связности
class CellPolygon {
   
   let threshold : Double
   var cells     : [Double]
   var field     : UnionSquare
   
   init(dimension : Int, threshold : Double) {
      
      self.threshold = threshold
      field = UnionSquare(width: dimension, height: dimension)
      cells = [Double]()
      
      for _ in 0..<dimension * dimension {
         cells.append(Double(arc4random())/Double(UInt32.max))
      }
      
      // строем связи
      calc()
   }
   
   func isOpen(_ item : (Int,Int)) -> Bool {
      return (cells[field.width * item.1 + item.0] < threshold)
   }
   
   /// построение двумерного поля
   private func calc() {
      for y in 0..<field.height {
         for x in 0..<field.width where isOpen((x,y)) {
            // связь с правой ячейкой
            if x<field.width-1 && isOpen((x+1,y)) {
               _ = field.union((x,y), (x+1,y))
            }
            // связь с нижней ячейкой
            if y<field.height-1 && isOpen((x,y+1)) {
               _ = field.union((x,y), (x,y+1))
            }
         }
         
         // процент выполненного расчета
         var _ = Double(y)/Double(field.height)
      }
   }
   
   /// наличие сквозных маршрутов через все поле
   /// - Returns : начальные и конечные точки маршрутов
   func crossPoints() -> [(Set<Int>, Set<Int>)] {
      
      var ways = [(Set<Int>, Set<Int>)]()
      
      // возвращает индекс группы верхнего слоя, с которой связана точка
      func connected(point:Int) -> Int? {
         for i in 0..<ways.count {
            for indx in ways[i].0 {
               if field.connected((indx,0), (point,0)) {
                  return i
               }
            }
         }
         return nil
      }
      
      // находим сквозные пути вида (0,1) -> <(h-1,5),(h-1,6)>
      for i in 0..<field.width where isOpen((i,0)) {
         
         // точка связана с другими точками верхнего слоя, 
         // для которых уже найдены пути
         if let indx = connected(point: i) {
            ways[indx].0.insert(i)
            continue
         }
         // не связанная
         var way = (Set<Int>([i]), Set<Int>())
         // ищем связи с конечным слоем
         for j in 0..<field.width where isOpen((j,field.height-1)) {
            if field.connected((i,0), (j,field.height-1)) {
               way.1.insert(j)
            }
         }
         if !way.1.isEmpty {
            ways.append(way)
         }
      }
      return ways
   }

   /// все связанные открытые точки от начала и до конца
   func crossAllPoints() -> [Set<Int>] {
      var res = [Set<Int>]()
      
      // получим начальные и конечные точки
      let cross = crossPoints()
      guard !cross.isEmpty else {
         return res
      }
      
      // жадный алгоритм: проверяем связанность всех точек
      // между начальными и конечными для поиска пути
      for path in cross {
         var way = Set<Int>()
         let last_line = field.height-1
         
         // добавим начальные и конечные точки
         for x in path.0 {
            way.insert(field.index((x,0)))
         }
         for x in path.1 {
            way.insert(field.index((x,last_line)))
         }
         
         let begin = (path.0.first!,0), end = (path.1.first!,last_line)
         // тупой перебор точек в остальных слоях
         for y in 1..<last_line {
            for x in 0..<field.width where isOpen((x,y)) {
               let pt = (x,y)
               if field.connected(pt, begin) && field.connected(pt, end) {
                  way.insert(field.index(pt))
               }
            }
         }
         // добавим путь
         res.append(way)
      }
      return res
   }

   /// расчет реального процента открытых ячеек
   var realThreshold : Double {
      var countOpen = 0
      
      for y in 0..<field.height {
         for x in 0..<field.width {
            if isOpen((x,y)) {
               countOpen += 1
            }
         }
      }
      return Double(countOpen)/Double(field.height*field.width)
   }
   
   /// распечатка поля
   func printCells(special : [Set<Int>]) {
      let symClosed = "⚫️", symOpen = "⚪️"
      let symSpec = ["🔴","🔵","💚","💛"]
      
      for y in 0..<field.height {
         var line = ""
         for x in 0..<field.width {
            if isOpen((x,y)) {
               let spec = special.index(where: { $0.contains(field.index((x,y))) })
               line    += (spec != nil) ? symSpec[spec! % symSpec.count] : symOpen
            }
            else {
               line += symClosed
            }
         }
         print(line)
      }
   }
}

/// Фабрика расчета вероятностей на полигоне
func calcProbabilitiesForCellField(dimension : Int, iterations : Int, probability : CountableClosedRange<Int>) {
   
   var statistics = [Int:(Int,Int)]()
   let stat_queue = DispatchQueue(label: "statistics.quaeue")
   
   print("calc avg. probability of cross connection for open state threshold's range \(probability)% with \(iterations) iterations for each, on cells field [\(dimension)x\(dimension)]")
   
   for p in probability {
      // параллелим
      DispatchQueue.concurrentPerform(iterations: iterations) { iter in
         let polygon   = CellPolygon(dimension: dimension, threshold: Double(p)/100)
         let cross     = polygon.crossPoints().isEmpty == false
         let threshold = Int(polygon.realThreshold * 100)
         
         // синхронизация результатов
         stat_queue.async {
            statistics[threshold]     = statistics[threshold] ?? (0,0)
            statistics[threshold]!.0 += cross ? 1 : 0
            statistics[threshold]!.1 += 1
            
            if iter == iterations-1 {
               print("done: \(Double(p-probability.lowerBound)/Double(probability.count)*100)%")
            }
         }
      }
   }
   
   // сортируем
   let sorted = statistics.sorted { $0.0 < $1.0 }
   for (key,val) in sorted {
      print("\(key)%\t\(Double(val.0)/Double(val.1)*100)% (\(val.1))")
   }
}

/// ищем два отдельных сквозных пути
func cellPolygonFindWays(dimension : Int, threshold : Double, ways_count : Int, max_iterations : Int = Int.max) -> Bool {
   var iterations = 0
   
   while (iterations < max_iterations) {
      let poly = CellPolygon(dimension: dimension, threshold: threshold)
      let ways = poly.crossPoints()
      
      iterations += 1
      if iterations % 10_000 == 0 {
         print("\(iterations) iterations done")
      }
      
      if ways.count != ways_count {
         continue
      }
      
      let fullways = poly.crossAllPoints()
      if fullways.count != ways_count {
         print("inconsistence")
         continue
      }
      
      poly.printCells(special: fullways)
      
      print("\(ways_count) ways finded after \(iterations) iterations on probability \(poly.realThreshold * 100)%")
      return true
   }
   return false
}

/// Фабрика расчета вероятностей на полигоне
func findProbabilitiesForCellFieldCrossWays(dimension : Int, ways_count : Int, max_iterations : Int, probability : CountableClosedRange<Int>) {
   
   // параллелим
   DispatchQueue.concurrentPerform(iterations: probability.count) { i in
      let p = probability.lowerBound + i
      
      print("finding \(ways_count) ways for probability \(p)%")
      _ = cellPolygonFindWays(dimension: dimension, threshold: Double(p)/100, ways_count: ways_count, max_iterations: max_iterations)
   }
}
