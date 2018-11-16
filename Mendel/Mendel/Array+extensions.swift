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
