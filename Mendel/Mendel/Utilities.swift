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

//Taken from https://gist.github.com/josephlord/e6298c724c0edadc3042#file-scanl1-swift
func scanl1<A>(input:[A], combiningF:(A,A)->A)->[A] {
    var running:A? = nil
    return input.map { (nv:A)->A in
        if let curr:A = running {
            let newVal = combiningF(curr, nv)
            running = newVal
            return newVal
        } else {
            running = nv
            return nv
        }
    }
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
