//
//  Operators.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public struct Operators
{
    public static func Crossover<I : Crossoverable>(probability:Probability, pop:[I])->[I]
    {
        var result = [I]()
        
        var generator = pop.shuffled().makeIterator()
        
        while let a = generator.next() {
            if let b = generator.next() {
                let crossed: [I] = chooseWithProbability(probability: probability, f: { return I.cross(parent1: a, parent2: b) }, g: { return [a,b] })
                
                result += crossed
            } else {
                result.append(a)
            }
        }
        
        return result
    }
    
    public static func Mutation<I : Mutatable>(probability:Probability, pop:[I])->[I]
    {
        var result = [I]()
        result.reserveCapacity(pop.count)
        for i in 0..<pop.count {
            let mutated: I = chooseWithProbability(
                probability: probability, f: { return I.mutate(individual: pop[i]) }, g: { return pop[i] }
            )
            result.append(mutated)
        }
        
        return result
    }
}

public protocol Mutatable : IndividualType {
    static func mutate(individual: Self) -> Self
}

public protocol Crossoverable : IndividualType {
    static func cross(parent1: Self, parent2: Self) -> [Self]
}
