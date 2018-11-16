//
//  TestViewController.swift
//  Example-iOS
//
//  Created by Patrick Niemeyer on 11/15/18.
//  Copyright © 2018 Saniul Ahmed. All rights reserved.
//

import Foundation
import UIKit
import Mendel


public class TestViewController: UIViewController
{
    override public func viewDidLoad() {
        //doScience()
    }
    
    var engine: SimpleEngine<Numbers>?
    
    func doScience()
    {
        let factory: SimpleEngine<Numbers>.Factory = { ()->Numbers in return Numbers.arbitraryOfLength(length: 10) }
        
        let engine: SimpleEngine<Numbers> = SimpleEngine<Numbers>(
            factory: { ()->Numbers in return Numbers.arbitraryOfLength(length: 10) },
            evaluation: { individual, population in return 0 },
            fitnessKind: FitnessKind.Inverted,
            selection: Selections.RouletteWheel,
            //Mutation is at 100%, since we control the by-gene probabilities
            //at the individual level
            op: { (pop:[Painting])->[Painting] in
                var newPop = Operators.Crossover(probability: 0.5, pop: pop)
                newPop = Operators.Mutation(probability: 1.0, pop: newPop)
                return newPop
            }
        )
        self.engine = engine

        var config = Configuration()
        config.size = 100
        config.eliteCount = 1
        
        engine.config = config
        engine.termination = { _ in return false } //Never terminate
        engine.iteration = { data in
            let best = data.bestCandidate
        }
        
        engine.evolve()
    }
}

struct Numbers: IndividualType
{
    var genes = [Int]()
    
    public init(genes: [Int]) {
        self.genes = genes
    }
    
    public static func arbitraryOfLength(length: Int) -> Numbers {
        return self.init( genes: (0..<length).map { _ in Int.random(in: 0...100) } )
    }
}

extension Numbers: Crossoverable {
    static func cross(parent1: Numbers, parent2: Numbers) -> [Numbers] {
        return [parent1, parent2]
    }
}

extension Numbers: Mutatable {
    static func mutate(individual: Numbers) -> Numbers {
        return individual
    }
}
