//
//  union.swift
//  QuickUnion
//
//  Created by quaerix on 08.01.17.
//  Copyright © 2017 quaerix. All rights reserved.
//

import Foundation

/// описание узла
struct Node {
   
   let id       : Int
   var ancestor : Int
   
   init(id : Int) {
      self.id  = id
      ancestor = id
   }
   
}

/**
 Класс описания узлов и их связей
 */
class Union {
   
   let dimension : Int
   var items     : [Node]
   var sizes     : [UInt]
   
   /// - Parameter dimension : количество узлов (*начинаются с нуля*)
   init(dimension : Int) {
      
      self.dimension = dimension
      self.items = [Node]()
      self.sizes = [UInt].init(repeating: 1, count: dimension)
      
      // инициализируем узлы с автоинкрементом
      for id in 0..<dimension {
         self.items.append(Node(id: id))
      }
   }
   
   /// поиск корней
   /// - Parameter item : элемент
   private func root(item : Int) -> Int {
      
      var root = item
      repeat {
         let ancestor = items[root].ancestor
         // укорачиваем высоту дерева
         items[root].ancestor = items[ancestor].ancestor
         root = items[root].ancestor
      } while (root != items[root].ancestor) // корень ссылается на себя
      
      return root
   }
   
   /// объединение двух узлов
   func union(_ item1 : Int,_ item2 : Int) {
      
      let root1 = root(item: item1)
      let root2 = root(item: item2)
      
      if root1 == root2 {
         return
      }
      
      func add(i : Int, j : Int) {
         items[i].ancestor = j
         sizes[j] += sizes[i]
      }
      
      if sizes[root1]<sizes[root2] {
         add(i: root1, j: root2)
      }
      else {
         add(i: root2, j: root1)
      }
   }
   
   /// проверка связности двух узлов
   func connected(_ item1 : Int,_ item2 : Int) -> Bool {
      return root(item: item1) == root(item: item2)
   }
   
   /// распечитка графа
   func printGraph() {
      
      var resume = [String].init(repeating: "", count: dimension)
      
      // составляем путь от каждого узла до корня
      for (indx,path) in resume.enumerated() {
         if (path.isEmpty) {
            var p = "\(indx)"
            var i = indx
            
            while (i != items[i].ancestor) {
               i = items[i].ancestor
               // если дошли до узла, у которого уже посчитан путь
               // просто дописываем его
               if (resume[i].isEmpty == false) {
                  p += " - \(resume[i])"
                  break
               }
               else {
                  p += " - \(i)"
               }
            }
            // итоговый путь
            resume[indx] = p
         }
      }
      
      // не выводим путь, если он содержится в другом
      genloop : for (gindx,gpath) in resume.enumerated() {
         for (indx,path) in resume.enumerated() {
            if (indx != gindx && path.contains(gpath)) {
               continue genloop
            }
         }
         print(gpath)
      }
   }
}

/// двумерное поле
class UnionSquare : Union {
   
   let width, height : Int
   
   init(width : Int, height : Int) {
      self.width  = width
      self.height = height
      
      super.init(dimension: width*height)
   }
   
   func index(_ pt : (Int,Int)) -> Int {
      return width * pt.1 + pt.0
   }
   
   /// проверка соседства клеток, соседями по диагонали быть нельзя
   func neighbor(_ item1: (Int,Int), _ item2: (Int,Int)) -> Bool {
      
      let intervalHorz = (0..<width)
      let intervalVert = (0..<height)
      
      guard intervalHorz.contains(item1.0) && intervalHorz.contains(item2.0) &&
         intervalVert.contains(item1.1) && intervalVert.contains(item2.1)
         else {
            return false
      }
      
      return (abs(item1.0 - item2.0) + abs(item1.1 - item2.1) == 1)
   }
   
   /// объединение двух узлов
   func union(_ item1: (Int,Int), _ item2: (Int,Int)) {
      super.union(index(item1), index(item2))
   }
   
   /// проверка связности двух узлов
   func connected(_ item1 : (Int,Int), _ item2 : (Int,Int)) -> Bool {
      return super.connected(index(item1), index(item2))
   }
}
