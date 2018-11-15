//
//  Termination.swift
//  genetic
//
//  Created by Saniul Ahmed on 20/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation

//MARK: Termination

public struct TerminationConditions {
    public static func NumberOfIterations<I : IndividualType>(maxNum: Int, data:IterationData<I>) -> Bool {
        return data.iterationNum >= maxNum
    }
    
    public static func OnDate<I : IndividualType>(date: Date, data:IterationData<I>) -> Bool {
        //return Date().earlierDate(date) == date
        return Date() >= date
    }
    
    public static func FitnessThreshold<I : IndividualType>(threshold: Fitness, fitnessKind: FitnessKind, data:IterationData<I>) -> Bool {
        return fitnessKind.comparisonOp(data.bestCandidateFitness, threshold)
    }
    
    public static func ReferenceIndividual<I : IndividualType>(reference: I, data:IterationData<I>) -> Bool where I : Comparable {
        return data.bestCandidate == reference
    }
    
}
