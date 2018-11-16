//
//  TestViewController.swift
//  Example-iOS
//
//  Created by Patrick Niemeyer on 11/15/18.
//  Copyright © 2018 Saniul Ahmed. All rights reserved.
//

import UIKit
import Mendel

public class TestViewController: UIViewController
{
    override public func viewDidLoad() {
        super.viewDidLoad()
        testSumNumbers(target: 42, length: 10)
    }
    
    func testSumNumbers(target: Int, length: Int)
    {
        let engine: SimpleEngine<Numbers> = SimpleEngine<Numbers>(
            factory: { return Numbers.arbitraryOfLength(length: length) },
            evaluation: { individual, population in
                return Double(abs(individual.genes.reduce(0, +) - target))
            },
            fitnessKind: FitnessKind.Inverted,
            
            // todo: confirm that RouletteWheel is implemented properly
            // It's slow and takes longer to converge.
            //selection: Selections.RouletteWheel,
            selection: Selections.StochasticUniversalSampling,
            //selection: Selections.SigmaScaling,
            
            op: { (pop:[Numbers])->[Numbers] in
                var newPop = Operators.Crossover(probability: 0.5, pop: pop)
                newPop = Operators.Mutation(probability: 0.1, pop: newPop)
                return newPop
            }
        )

        var config = Configuration()
        config.size = 100
        config.eliteCount = 1
        
        engine.config = config
        engine.termination = { data in
            return data.bestCandidateFitness == 0
        }
        engine.iteration = { data in
            //print("iteration: \(data.iterationNum), best score: \(data.bestCandidateFitness), best: \(data.bestCandidate)")
        }
        
        let n = 10
        let stats = Stats([Double]())
        for i in 0..<n {
            let iter = engine.evolve()
            let its = iter.iterationNum
            print("run: \(i), iterations = \(its)")
            stats.addValue(val: Double(its))
        }
        print("median iterations after \(n) runs: \(stats.median)")
    }
}

struct Numbers: IndividualType, Crossoverable, Mutatable, CustomStringConvertible
{
    var genes: [Int]
    
    public init(genes: [Int]) {
        self.genes = genes
    }
    
    public var description: String {
        return "Numbers: \(genes)"
    }
    
    public static func arbitraryOfLength(length: Int) -> Numbers {
        return self.init( genes: (0..<length).map { _ in Int.random(in: 0...100) } )
    }
    
    static func cross(parent1 parentA: Numbers, parent2 parentB: Numbers) -> [Numbers] {
        //print("cross: \(parent1.genes), \(parent2.genes)")

        var childA = parentA.genes
        var childB = parentB.genes
        let count = parentA.genes.count
        var i1 = Int.random(in: 0..<count)
        var i2 = Int.random(in: 0..<count)
        if (i1 > i2) { swap(&i1, &i2) }
        let range = i1..<i2
        childA.replaceSubrange(range, with: parentB.genes[range])
        childB.replaceSubrange(range, with: parentA.genes[range])

        //print("cross: \(parentA.genes, parentB.genes) = \(childA, childB)")
        return [self.init(genes: childA), self.init(genes: childB)]
    }
    
    static func mutate(individual: Numbers) -> Numbers {
        //print("mutate: \(individual.genes)")
        return Numbers( genes: individual.genes.map {
            //$0 + (roll(probability: 0.1) ? Int.random(in: -1...1) : 0)
            $0 + Int.random(in: -1...1)
        })
    }
}

