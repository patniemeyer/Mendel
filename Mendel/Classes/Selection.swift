//
//  Selection.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

public struct Selection
{
    public static func truncation<I : IndividualType>(
        truncationPoint: Double, pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        //let truncationCount = Int(floor(truncationPoint * Double(pop.count)))
        
        let slice = pop[0..<count]
        let result = Array(slice)
        return result.map { $0.individual }
    }
    
    public static func random<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        var selected = [I]()
        
        for _ in 0..<count {
            selected.append(pickRandom(from:pop).individual)
        }
        
        return selected
    }
    
    public static func tournament2<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        return tournament(size: 2, pop: pop, fitnessKind: fitnessKind, count: count)
    }
    
    public static func tournament<I : IndividualType>(
        size: Int, pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        var selection = [I]()
        
        let sortLambda = { (a: Score<I>, b:Score<I>) -> Bool in
            return fitnessKind.comparisonOp(a.fitness, b.fitness)
        }
        
      iterateWhile(condition: { return $0 < count }, initialValue: 0) { i in
            let individuals = (0..<size).map { _ -> Score<I> in return pickRandom(from: pop) }
            let sorted = individuals.sorted(by: sortLambda)
            selection.append(sorted.first!.individual)
            
            return selection.count
        }
        
        return selection
    }
    
    // Probability proportional to normalized fitness (pi = fi / sum(f[0..n]))
    // (the slice of the wheel for an individual is its fraction of the total fitness)
    public static func rouletteWheelNew<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        let fitnesses = pop.map { fitnessKind.adjustedFitness(fitness:$0.fitness) }
        var selection = [I]()
        while selection.count < count {
            selection.append(pop[fitnesses.weightedRandomIndex()].individual)
        }
        return selection
    }
    
    public static func rouletteWheelBroken<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        let fitnesses = pop.map { $0.fitness }
        
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
        
        let cumulative = scanl1(input: fitnesses) { acc, val -> Double in
            acc + fitnessKind.adjustedFitness(fitness: val)
        }
        
        var selection = [I]()
        
        while selection.count < count {
            let randomFitness = Double(randomP()) * cumulative.last!
            let idx = insertionPoint(domain: fitnesses, searchItem: randomFitness)
            selection.append(pop[idx].individual)
        }
        
        return selection
    }
    
    public static func cloneBest<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        var selection = [I]()
        while selection.count < count {
            selection.append(pop[0].individual)
        }
        return selection
    }
    
    public static func stochasticUniversalSampling<I : IndividualType>(
        pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        let adjustedFitnesses = pop.map { score -> Fitness in
            return fitnessKind.adjustedFitness(fitness: score.fitness)
        }
        
        let sum = adjustedFitnesses.reduce(0, +)
        let startOffset = Double.random(in: 0...1)
        var cumulativeExpectation: Double = 0
        var idx = 0
        var selection = [I]()
        for score in pop {
            let adjusted = fitnessKind.adjustedFitness(fitness: score.fitness)
            cumulativeExpectation += adjusted / sum * Double(count)
            
            while (cumulativeExpectation > startOffset + Double(idx)) {
                selection.append(score.individual);
                idx+=1
            }
        }
        
        return selection
    }
    
    // Scale fitness by the standard deviation to adjust selection pressure to fit the population
    public static func sigmaScaling<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I]
    {
        let fitnesses = pop.map { $0.fitness }
        
        let stats: Stats = Stats(fitnesses)
        
        let mean = stats.arithmeticMean
        let stdev = stats.stdev
        
        let scaledPop = pop.map { score -> Score<I> in
            let scaled = self.sigmaScaled(fitness: score.fitness, mean: mean, stdev: stdev)
            return Score<I>(fitness: scaled, individual: score.individual)
        }
        
        return stochasticUniversalSampling(pop: scaledPop, fitnessKind: fitnessKind, count: count)
    }
    
    private static func sigmaScaled(fitness: Double, mean: Double, stdev: Double) -> Double {
        if stdev == 0 {
            return 1
        } else {
            let scaled = 1 + (fitness - mean) / (2 * stdev)
            return scaled > 0 ? scaled : 0.1
        }
    }
    
    public static func rankSelection<I : IndividualType>(pop: [Score<I>], fitnessKind: FitnessKind, count: Int) -> [I] {
        let mappedPop = (pop.enumerated()).map { (arg) -> Score<I> in
            let (idx, score) = arg
            return Score(fitness: self.rankMapped(rank: idx+1, populationSize: pop.count), individual: score.individual)
        }
        
        return stochasticUniversalSampling(pop: mappedPop, fitnessKind: fitnessKind, count: count)
    }
    
    private static func rankMapped(rank: Int, populationSize: Int) -> Double {
        return Double(populationSize - rank)
    }
}
