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

public class ImageMatchingLab {
    var referenceImageURL: URL!
    var outputImageSize: CGSize?
    var output: ((CGImage, Int) -> Void)?
    
    var engine: SimpleEngine<Painting>?
    
    public init () {
    }
    
    func doScience() {
        let engine = SimpleEngine<Painting>(
            factory: { ()->Painting in return Painting.arbitraryOfLength(length: 50) },
            evaluation: distanceFromTargetImageAtURL(imageURL: self.referenceImageURL),
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
        config.size = 200
        config.eliteCount = 1
        
        engine.config = config
        engine.termination = { _ in return false } //Never terminate
        engine.iteration = { data in
            let best = data.bestCandidate
            
            if let size = self.outputImageSize {
                self.output?(best.imageOfSize(size: size), data.iterationNum)
            }
        }
        
        engine.evolve()
    }
    
    func stop() {
        self.engine?.termination = { _ in return true }
        self.engine = nil
    }
}

//MARK: Structures

struct Painting : IndividualType {
    let genes: [Gene]
    
    init(_ genes: [Gene]) {
        self.genes = genes
    }
    
    func drawInContext(context: CGContext, size: CGSize) {
        context.setFillColor(UIColor.black.cgColor)
        context.fill(CGRect(origin: CGPoint.zero, size: size))
        for gene in self.genes {
            gene.drawInContext(context: context, size: size)
        }
    }
}

struct Gene {
    let color: Color
    let triangle: Triangle
    
    func drawInContext(context: CGContext, size: CGSize) {
        context.setFillColor(red: CGFloat(color.r)/255, green: CGFloat(color.g)/255, blue: CGFloat(color.b)/255, alpha: CGFloat(color.a)/255)
        triangle.drawInContext(context: context, size:size)
    }
}

struct Color {
    let r,g,b,a: UInt8
}

struct Triangle {
    let a: CGPoint
    let b: CGPoint
    let c: CGPoint
    
    func drawInContext(context: CGContext, size: CGSize) {
        let sA = self.a.scaledUnitPoint(size: size)
        let sB = self.b.scaledUnitPoint(size: size)
        let sC = self.c.scaledUnitPoint(size: size)
        
        context.move(to: CGPoint(x: sA.x, y: sA.y))
        context.addLine(to: CGPoint(x: sB.x, y: sB.y))
        context.addLine(to: CGPoint(x: sC.x, y: sC.y))
        context.closePath();
        context.fillPath();
    }
}

extension CGPoint {
    func scaledUnitPoint(size:CGSize) -> CGPoint {
        return CGPoint(x: self.x*size.width, y: self.y*size.height)
    }
}

//MARK: Crossover and Mutation

//TODO: Generalize finite sequence based crossover
extension Painting : Crossoverable {
    static func cross(parent1: Painting, parent2: Painting) -> [Painting] {
        let wordA = parent1.genes
        let wordB = parent2.genes
        
        let c = wordA.count
        var p1 = Int(arc4random_uniform(UInt32(c)))
        var p2 = Int(arc4random_uniform(UInt32(c)))
        if (p1 > p2) {
            swap(&p1, &p2)
        }
        
        //let subRange = Range<Int>(start: p1, end: p2)
        let subRange = p1..<p2
        var childB = wordB
        childB.replaceSubrange(subRange, with: wordA[subRange])
        var childA = wordA
        childA.replaceSubrange(subRange, with: wordB[subRange])
        
        return [self.init(childA), self.init(childB)]
    }
}

//TODO: Generalize finite sequence based mutation
extension Painting : Mutatable {
    static func mutate(individual:Painting) -> Painting {
        var dna = [Gene]()
        dna.reserveCapacity(individual.genes.count)
        for gene in individual.genes {
            if roll(probability: 0.1) {
                dna.append(Gene.mutate(individual: gene))
            } else {
                dna.append(gene)
            }
        }
        
        return Painting(dna)
    }
}

extension Gene : Mutatable {
    @inline(__always) static func mutate(individual: Gene) -> Gene {
        let color = roll(probability: 0.1) ? Color.mutate(individual: individual.color) : Color.drift(individual: individual.color)
        let triangle = roll(probability: 0.1) ? Triangle.mutate(individual: individual.triangle) : Triangle.drift(individual: individual.triangle)
        
        return Gene(color: color, triangle: triangle)
    }
}

extension Color {
    @inline(__always) static func mutate(individual: Color) -> Color {
        let mR = UInt8.arbitrary()
        let mG = UInt8.arbitrary()
        let mB = UInt8.arbitrary()
        let mA = UInt8.arbitrary()
        
        return Color(r: mR, g: mG, b: mB, a: mA)
    }
    
    @inline(__always) static func drift(individual: Color) -> Color {
        let op : (UInt8, UInt8)->UInt8 = coinFlip() ? (&+) : (&-)
        
        let mR = op(individual.r, 1)
        let mG = op(individual.g, 1)
        let mB = op(individual.b, 1)
        let mA = op(individual.a, 1)
        
        return Color(r: mR, g: mG, b: mB, a: mA)
    }
}

extension Triangle {
    @inline(__always) static func arbitrary() -> Triangle {
        return Triangle(a: CGPoint.randomUnit(), b: CGPoint.randomUnit(), c: CGPoint.randomUnit())
    }
}

extension Triangle {
    @inline(__always) static func mutate(individual:Triangle) -> Triangle {
        let mA = CGPoint.randomUnit()
        let mB = CGPoint.randomUnit()
        let mC = CGPoint.randomUnit()
        
        return Triangle(a: mA, b: mB, c: mC)
    }
    
    @inline(__always) static func drift(individual: Triangle) -> Triangle {
        let mA = CGPoint.drift(individual: individual.a)
        let mB = CGPoint.drift(individual: individual.b)
        let mC = CGPoint.drift(individual: individual.c)
        
        return Triangle(a: mA, b: mB, c: mC)
    }
}

extension CGPoint {
    @inline(__always) static func drift(individual: CGPoint) -> CGPoint {
        let op : (CGFloat, CGFloat)->CGFloat = coinFlip() ? (+) : (-)
        
        let newPoint = CGPoint(x: min(1.5,max(-0.5,op(individual.x, 0.01))), y: min(1.5,max(-0.5,op(individual.y, 0.01))))
        return newPoint
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

//MARK: Rendering

extension Painting {
    func imageOfSize(size: CGSize) -> CGImage {
        let colorSpace: CGColorSpace = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipLast.rawValue)
        let width = Int(size.width)
        let height = Int(size.height)
        let bytesPerRow = Int(width) * 4
        let context = CGContext(data: nil, width: width, height: height, bitsPerComponent: 8, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: bitmapInfo.rawValue)!
//        CGContextSetShouldAntialias(context, false);
        self.drawInContext(context: context, size: size)
        return context.makeImage()!
    }
}

//MARK: Random/Arbitrary Instances

extension Painting {
    static func arbitraryOfLength(length: Int) -> Painting {
        let dna : [Gene] = (0..<length).map { _ in
            return Gene.arbitrary()
        }
        
        return self.init(dna)
    }
}

extension CGImage {
    public var size: CGSize {
        return CGSize(width: self.width, height: self.height)
    }
}

extension Gene {
    @inline(__always) static func arbitrary() -> Gene {
        let color = Color.arbitrary()
        let triangle = Triangle.arbitrary()
        
        return self.init(color: color, triangle: triangle)
    }
}

extension Color {
    @inline(__always) static func arbitrary() -> Color {
        return Color(r: UInt8.arbitrary(), g: UInt8.arbitrary(), b: UInt8.arbitrary(), a: UInt8.arbitrary())
    }
}

extension UInt8 {
    @inline(__always) static func arbitrary() -> UInt8 {
        return UInt8(arc4random_uniform(UInt32(UInt8.max)))
    }
}

extension CGFloat {
    @inline(__always) static func random(from:CGFloat, to: CGFloat) -> CGFloat {
        return from + (to-from)*(CGFloat(arc4random()) / CGFloat(UInt32.max))
    }
    
    @inline(__always) static func randomUnit() -> CGFloat {
        return self.random(from: 0, to: 1)
    }
}

extension CGPoint {
    @inline(__always) static func random(from:CGFloat, to: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(from: from, to: to), y: CGFloat.random(from: from, to: to))
    }
    
    @inline(__always) static func randomUnit() -> CGPoint {
        return self.random(from: -0.5, to: 1.5)
    }
}
