//
//  genetic.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import Foundation

//MARK: Core Types

//Types of individuals to be evolved have to conform to this type
public protocol IndividualType { }

//The Genetic Engine protocol
public protocol Engine {
    //The type that's being evolved
    associatedtype Individual : IndividualType
    
    //A collection of Individuals
    typealias Population = [Individual]
    
    //A collection of Individuals and their respective fitness scores
    typealias EvaluatedPopulation = [Score<Individual>]
    
    //MARK: Core function types
    
    //Used to instantiate a new arbitrary Individual
    typealias Factory = (() -> Individual)
    
    //Used to ge a fitness score for an Individual in a given Population
    typealias Evaluation = (Individual, Population) -> Fitness
    
    //Selection Function - used to select the next iteration's Population from
    //the current EvaluatedPopulation
    typealias Selection = (EvaluatedPopulation, FitnessKind, Int) -> Population
    
    //The Genetic Operator that is going to be called to modify the selected Population
    typealias Operator = (Population) -> Population
    
    //Termination predicate. When it returns yes, the evolution process is stopped
    typealias Termination = (IterationData<Individual>) -> Bool
    
    ////////////////////////////////////////////////////////////////////////////
    
    var fitnessKind: FitnessKind { get }
    
    var factory: Factory { get }
    
    var evaluation: Evaluation { get }
    
    var selection: Selection { get }
    
    var op: Operator { get }
    
    var termination: Termination? { get }
    
    //Called after each evolution step. Useful to update UI/inform user.
    var iteration: ((IterationData<Individual>) -> Void)? { get }
    
    //Starts the evolution process. This is a blocking call, it won't return until
    //`termination` returns true – make sure you aren't blocking UI.
    func evolve() -> Individual
}

//Represents the relationship between two fitness values
//Defines whether a greater Fitness value should be considered better or worse
public enum FitnessKind {
    case Natural
    case Inverted
    
    var comparisonOp:(_ lhs: Fitness, _ rhs: Fitness) -> Bool {
        switch self {
        case .Natural :
            return (>)
        case .Inverted:
            return (<)
        }
    }
    
    func adjustedFitness(fitness: Fitness) -> Fitness {
        switch self {
        case .Natural:
            return fitness
        case .Inverted:
            if fitness == 0 {
                return Double.infinity
            } else {
                return 1.0/fitness
            }
        }
    }
}

public typealias Fitness = Double
//Represents an evaluated individual
public struct Score<Individual : IndividualType> : CustomStringConvertible {
    let fitness: Fitness
    let individual: Individual
    
    public var description: String {
        return "\(self.individual):\(self.fitness)"
    }
    
    func fitterIndividual(fitnessKind:FitnessKind, other: Score<Individual>) -> Individual {
        if fitnessKind.comparisonOp(self.fitness, other.fitness) {
            return self.individual
        } else {
            return other.individual
        }
    }
}

//Provides various stats regarding the current state of evolution
public struct IterationData<I : IndividualType> : CustomStringConvertible {
    init(iterationNum: Int, pop:[Score<I>], fitnessKind: FitnessKind, config: Configuration) {
        self.iterationNum = iterationNum
        
        let bestScore = pop.first!
        
        self.bestCandidate = bestScore.individual
        self.bestCandidateFitness = bestScore.fitness
        
        let stats = Stats(pop.map { $0.fitness })
        
        self.fitnessMean = stats.arithmeticMean
        self.fitnessStDev = stats.stdev
        
        self.fitnessKind = fitnessKind
    }
    
    public let iterationNum: Int
    
    public let bestCandidate: I
    public let bestCandidateFitness: Fitness
    
    public let fitnessMean: Fitness
    public let fitnessStDev: Fitness
    
    public let fitnessKind: FitnessKind
    
    public var description: String {
        return "#\(iterationNum):\(bestCandidate)"
    }
}

//MARK: Genetic Engine helper functions
//These can be used by various concrete implementations of the Engine protocol

//Generates an initial population using the provided factory function
public func primordialSoup<I : IndividualType>(size: Int, factory:()->I) -> [I] {
    return (0..<size).map { _ -> I in
        factory()
    }
}

//Evaluates the population using the provided evaluation function
//This used to be a nice little function but got really ugly after being modified to
//support concurrent computation by partitioning the population
public func evaluatePopulation<I : IndividualType>(population: [I], withStride stride: Int, evaluation:@escaping (I, [I]) -> Fitness) -> [Score<I>] {
    let queue = DispatchQueue.global()
    
    var scores: [Score<I>] = [Score<I>]()
    scores.reserveCapacity(population.count)
    
    let writeQueue = DispatchQueue(label: "scores write queue")
    
    let group = DispatchGroup()
    
    //TODO: write this in a more swifty way
    let iterations = Int(population.count/stride)
    func evaluatePopulationClosure(idx: Int) -> (Void) {
        var j = Int(idx) * stride
        let j_stop = j + stride
        repeat {
            group.enter()
            let ind = population[j]
            let fitness = evaluation(ind, population)
            writeQueue.async() {
                scores.append(Score(fitness: fitness, individual: ind))
                group.leave()
            }
            j+=1
        } while (j < j_stop);
    }
    DispatchQueue.concurrentPerform(iterations: iterations, execute: evaluatePopulationClosure)
    
    //handle the remainder
    group.enter()
    queue.async() {
        let startIdx = Int(iterations) * stride
        let remainder: [Score<I>] = (population[startIdx..<population.count]).map { ind -> Score<I> in return Score(fitness: evaluation(ind, population), individual: ind)
        }
        
        writeQueue.async() {
            scores.append(contentsOf: remainder)
            group.leave()
        }
    }
    
    _ = group.wait(timeout: DispatchTime.distantFuture)

    return scores
}

//Sorts the evaluated population based on the provided fitness kind
public func sortEvaluatedPopulation<I : IndividualType>(population: [Score<I>], fitnessKind:FitnessKind) -> [Score<I>] {
    let sorted = population.sorted { return fitnessKind.comparisonOp($0.fitness, $1.fitness) }
    //let fitnesses = population.map { $0.fitness }
    return sorted
}

//MARK: Generational Engine

//A Simple generational genetic engine implementation
public class SimpleEngine<Individual : IndividualType> : Engine
{
    let threads = 8
    
    //These type definitions have to be repeated here, even though we already
    //described them in Engine :( Not sure why...
    //TODO: find out why
    
    //MARK: Engine

    public typealias Factory = () -> Individual
    
    public typealias Population = [Individual]
    public typealias EvaluatedPopulation = [Score<Individual>]
    
    public typealias Evaluation = (Individual, Population) -> Fitness
    public typealias Operator = (Population) -> Population
    public typealias Selection = (EvaluatedPopulation, FitnessKind, Int) -> Population
    
    public typealias Termination = (IterationData<Individual>) -> Bool
    
    public let factory: Factory
    public let fitnessKind: FitnessKind
    public let selection: Selection
    public let op: Operator
    
    public let evaluation: Evaluation
    
    public var termination: Termination?
    
    public var iteration: ((IterationData<Individual>) -> Void)?
    
    ////////////////////////////////////////////////////////////////////////////
    
    public init(
        factory: @escaping Factory,
        evaluation: @escaping Evaluation,
        fitnessKind: FitnessKind,
        selection: @escaping Selection,
        op: @escaping Operator) {
            self.factory = factory
            self.evaluation = evaluation
            self.fitnessKind = fitnessKind
            self.selection = selection
            self.op = op
            self.config = Configuration()
    }
    
    public var config: Configuration
    
    //The core work function. This runs on the calling thread, blocking it
    //while the evolution is running.
    //TODO: Clean up the implementation (avoid repetition, more functional style...)
    @discardableResult
    public func evolve() -> Individual {
        let pop = primordialSoup(size: self.config.size, factory: self.factory)
        
        let stride = pop.count / threads
        var evaluatedPop = evaluatePopulation(population: pop, withStride:stride, evaluation: self.evaluation)
        var sortedEvaluatedPop = sortEvaluatedPopulation(population: evaluatedPop, fitnessKind: self.fitnessKind)
        
        var iterationIdx = 0
        
        var data = IterationData(iterationNum: iterationIdx, pop: sortedEvaluatedPop, fitnessKind: self.fitnessKind, config: self.config)
        self.iteration?(data)
        
        while (self.termination == nil || self.termination!(data) == false) {
            evaluatedPop = step(pop: sortedEvaluatedPop)

            sortedEvaluatedPop = sortEvaluatedPopulation(population: evaluatedPop, fitnessKind: self.fitnessKind)
            
            iterationIdx+=1
            
            data = IterationData(iterationNum: iterationIdx, pop: sortedEvaluatedPop, fitnessKind: self.fitnessKind, config: self.config)
            self.iteration?(data)
        }
        
        return data.bestCandidate
    }
    
    //Evolution iteration logic
    func step(pop: EvaluatedPopulation) -> EvaluatedPopulation {
        //let elites = map(pop[0..<self.config.eliteCount]) { $0.individual }
        let elites = (pop[0..<self.config.eliteCount]).map { $0.individual }
        
        let normalCount = pop.count - elites.count
        
        var selectedPop = self.selection(pop, self.fitnessKind, normalCount)

        //TODO: parametrize?
        while selectedPop.count < normalCount {
            selectedPop += Selections.Random(pop: pop, fitnessKind: self.fitnessKind, count: normalCount - selectedPop.count)
        }
        
        var mutatedPop = self.op(Array(selectedPop[0..<selectedPop.count]))
        
        //TODO: parametrize?
        while mutatedPop.count < normalCount {
            mutatedPop.append(self.factory())
        }
        
        let newPop = elites + mutatedPop
        
        let stride = newPop.count / threads
        let newEvaluatedPop = evaluatePopulation(population: newPop, withStride:stride, evaluation: self.evaluation)
        
        return newEvaluatedPop
    }
}

//SimpleEngine parametrization
public struct Configuration {
    public init() {
    }
    
    public var size = 250
    public var eliteCount = 1
}
