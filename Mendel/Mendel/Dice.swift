//
//  dice.swift
//  genetic
//
//  Created by Saniul Ahmed on 05/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public typealias Probability = Float

public func coinFlip() -> Bool {
    return arc4random_uniform(2) == 0
}

public func roll(probability: Probability) -> Bool {
    if (probability == 1.0) {
        return true
    } else if (probability == 0.0) {
        return false
    }
    
    let roll = randomP()
    return probability > roll
}

func randomP() -> Probability {
    return Probability.random(in: 0.0...1.0)
}

func random(from: Int, to: Int) -> Int {
    return Int.random(in: from...to)
}

func random(from:Float, to: Float) -> Float {
    return Float.random(in: from...to)
}

func random(from:Double, to: Double) -> Double {
    return Double.random(in: from...to)
}

func pickRandom<T>(from array: Array<T>) -> T {
    return array[Int.random(in: 0..<array.count)]
}

func withProbability<Result>(probability: Probability, f: () -> Result) -> Result? {
    if roll(probability: probability) {
        return f()
    }
    
    return nil
}

func chooseWithProbability<Result>(probability: Probability, f: () -> Result, g: () -> Result) -> Result {
    if roll(probability: probability) {
        return f()
    } else {
        return g()
    }
}

func pickFromRange<T: Strideable>(range:Range<T>, withProbability probability: Probability) -> [T] where T.Stride: SignedInteger
{
    var selected = [T]()
    for i in range {
        withProbability(probability: probability) {
            selected.append(i)
        }
    }
    
    return selected
}

