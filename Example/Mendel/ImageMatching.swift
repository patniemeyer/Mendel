//
//  ImageMatching.swift
//  genetic
//
//  Created by Saniul Ahmed on 04/01/2015.
//  Copyright (c) 2015 Saniul Ahmed. All rights reserved.
//

import Foundation
import QuartzCore
import ImageIO
import UIKit

import Mendel

public class ImageMatching
{
    var referenceImageURL: URL!
    var outputImageSize: CGSize?
    var output: ((CGImage, Int) -> Void)? // todo: remove
    var iteration: ((IterationData<Painting>)->Void)?
    
    var engine: SimpleEngine<Painting>?
    
    public init () { }
    
    func run() {
        let engine = SimpleEngine<Painting>(
            factory: { ()->Painting in return Painting.arbitraryOfLength(length: 50) },
            evaluation: distanceFromTargetImageAtURL(imageURL: self.referenceImageURL),
            fitnessKind: FitnessKind.inverted,
            
            selection: Selection.cloneBest, // 1000 iters, ~4000
            //selection: Selection.rouletteWheelNew, // 1000 iters ~5800 fitness
            //selection: Selection.rouletteWheelBroken, // 1000 iters ~4100 fitness
            //selection: Selection.sigmaScaling, // 1000 iters ~4800-5300? fitness
            //selection: Selection.stochasticUniversalSampling, // 1000 iters, ~5300-6400 fitness
            //selection: Selection.tournament2, // 1000 iters ~5400 fitness
            
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
        //engine.termination = { data in return data.iterationNum == 1000 }
        engine.termination = { data in return false }
        engine.iteration = { data in self.iteration?(data) }
        
        engine.evolve()
    }
    
    func stop() {
        self.engine?.termination = { _ in return true }
        self.engine = nil
    }
}

// MARK: Fitness calculation

struct Pixel {
    let red: UInt8
    let blue: UInt8
    let green: UInt8
    let alpha: UInt8
}

private func distance(a: Pixel, b: Pixel) -> Fitness {
    let r = Fitness(a.red) - Fitness(b.red)
    let g = Fitness(a.green) - Fitness(b.green)
    let b = Fitness(a.blue) - Fitness(b.blue)
    
    return r*r + g*g + b*b
}

private func distanceFromTargetImageAtURL(imageURL: URL) -> (Painting, [Painting]) -> Fitness {
    guard let dataProvider = CGDataProvider(url: imageURL as CFURL) else {
        fatalError("data provider")
    }
    let options = [
        (kCGImageSourceThumbnailMaxPixelSize as String): 75 as CFNumber,
        (kCGImageSourceCreateThumbnailFromImageIfAbsent as String): true
        ] as [String : Any]
    
    guard let imageSource = CGImageSourceCreateWithDataProvider(dataProvider, options as CFDictionary) else {
        fatalError("image source")
    }
    
    //var count = CGImageSourceGetCount(imageSource)
    
    let targetImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary)!
    //let img = UIImage(cgImage: targetImage)
    
    let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
    let width  = Int( targetImage.width )
    let height = Int(  targetImage.height )
    let bytesPerRow = width * 4
    
    let length = Int(width)*Int(height)

    let buffer = UnsafeMutablePointer<Pixel>.allocate(capacity: length)
    let targetcontext = CGContext(data: buffer, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
    targetcontext.setFillColor(UIColor.black.cgColor)
    targetcontext.draw(targetImage, in: CGRect(origin: CGPoint.zero, size: targetImage.size))

    let distance = distanceFromTargetImageData(targetData: buffer, withSize: targetImage.size)

    return distance
}

private func distanceFromTargetImageData(targetData: UnsafeMutablePointer<Pixel>, withSize size: CGSize) -> (Painting, [Painting]) -> Fitness {
    return { painting, _ in
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = Int(width) * 4
        
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
        painting.drawInContext(context: context, size: size)
        
        var data = unsafeBitCast((context.data)!, to: UnsafeMutablePointer<Pixel>.self)
        
        var sum = 0.0
        for y in 0..<height {
            for x in 0..<width {
                let targetpx = targetData[Int(x + y * width)]
                let px = data[Int(x + y * width)]
                let dist = distance(a: targetpx, b: px)
                sum += dist
            }
        }
        
        
        return sqrt(sum)
    }
}

