//
//  std.swift
//  genetic
//
// Based on FunSwift Book's appendix code

import Foundation

//The iterateWhile function repeatedly applies a function while the condition holds.
@discardableResult
func iterateWhile<A>(condition: (A) -> Bool,
    initialValue: A,
    next: (A) -> A?) -> A {
        
        if let x = next(initialValue) {
            if condition(x) {
                return iterateWhile(condition: condition, initialValue: x, next: next)
            }
        }
        return initialValue
}

func insertionPoint<C : Collection>(domain: C, searchItem: C.Element) -> C.Index where C.Element : Comparable, C.Index == Int {
    var lowerIndex = domain.startIndex
    var upperIndex = domain.endIndex - 1
    
    while (true) {
        let currentIndex = (lowerIndex + upperIndex)/2
        //let item = domain[currentIndex]
        
        if (domain[currentIndex] == searchItem) {
            return currentIndex
        } else if (lowerIndex >= upperIndex) {
            return lowerIndex
        } else {
            if (domain[currentIndex] > searchItem) {
                //upperIndex = currentIndex.predecessor()
                upperIndex = currentIndex - 1
            } else {
                //lowerIndex = currentIndex.successor()
                lowerIndex = currentIndex + 1
            }
        }
    }
}
