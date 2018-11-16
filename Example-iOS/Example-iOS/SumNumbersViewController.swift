//
//  TestViewController.swift
//  Example-iOS
//
//  Created by Patrick Niemeyer on 11/15/18.
//

import UIKit
import Mendel

public class SumNumbersViewController: UIViewController
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
            fitnessKind: FitnessKind.inverted,
            
            // todo: confirm that RouletteWheel is implemented properly
            // It's slow and takes longer to converge.
            //selection: Selections.rouletteWheel,
            selection: Selection.stochasticUniversalSampling,
            //selection: Selections.sigmaScaling,
            
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
    
    public var description: String { return "Numbers: \(genes)" }
    
    public static func arbitraryOfLength(length: Int) -> Numbers {
        let min = 0, max = 100
        return self.init( genes: (0..<length).map { _ in Int.random(in: min...max) } )
    }
    
    static func cross(parent1 parentA: Numbers, parent2 parentB: Numbers) -> [Numbers] {
        let children = Array<Int>.swapRandomSubrange(a: parentA.genes, b: parentB.genes)
        //print("cross: \(parentA.genes, parentB.genes) = \(children)")
        return children.map { self.init(genes: $0) }
    }
    
    static func mutate(individual: Numbers) -> Numbers {
        //print("mutate: \(individual.genes)")
        let perGeneProb: Float = 0.5
        return Numbers( genes: individual.genes.map {
            $0 + (roll(probability: perGeneProb) ? Int.random(in: -1...1) : 0)
        })
    }
}
