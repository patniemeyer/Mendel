//
//  Array+extensions.swift
//  Mendel
//
//  Created by Patrick Niemeyer on 11/16/18.
//

import Foundation

public extension Array
{
    public func randomSubrange() -> Range<Int> {
        let count = self.count
        var i1 = Int.random(in: 0..<count)
        var i2 = Int.random(in: 0..<count)
        if (i1 > i2) { swap(&i1, &i2) }
        return i1..<i2
    }
    
    // Swap the subrange between a and b and return an array of the transformed a and b
    public static func swapRange<E>(a: [E], b: [E], range: Range<Int>) -> [[E]] {
        var childA = a
        var childB = b
        childA.replaceSubrange(range, with: b[range])
        childB.replaceSubrange(range, with: a[range])
        return [childA, childB]
    }
    
    // Swap a random subrange of a and b and return an array of the transformed a and b
    public static func swapRandomSubrange<E>(a: [E], b: [E]) -> [[E]] {
        return swapRange(a: a, b: b, range: a.randomSubrange())
    }
}

public extension Array where Element == Double {
    
    /// Consider the elements as weight values and return a weighted random selection by index.
    /// a.k.a Roulette wheel selection.
    /// https://stackoverflow.com/a/15582983/74975
    func weightedRandomIndex() -> Int
    {
        var selected: Int = 0
        var total: Double = self[0]
        
        for i in 1..<self.count { // start at 1
            total += self[i]
            if( Double.random(in: 0...1) <= (self[i] / total)) { selected = i }
        }
        
        return selected
    }
    
    func normalized(inverted: Bool = false) -> [Double] {
        let sum = self.reduce(0,+)
        let normalized = self.map { $0/sum }
        if inverted {
            return normalized.map { 1.0 - $0 }.normalized()
        } else {
            return normalized
        }
    }
}

// TODO: Get this to work for all Numeric?
public extension Array where Element == Float {
    
    func weightedRandomIndex() -> Int {
        return self.map { Double($0) }.weightedRandomIndex()
    }
    
}
