//
//  Painting.swift
//  evolve-vgg
//
//  Created by Patrick Niemeyer on 11/20/18.
//  Copyright © 2018 net.pat. All rights reserved.
//

import Foundation
import UIKit
import Mendel

public struct Painting : IndividualType {
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

public struct Gene {
    public let color: Color
    public let triangle: Triangle
    
    public init( color: Color, triangle: Triangle ) {
        self.color = color
        self.triangle = triangle
    }
    
    public func drawInContext(context: CGContext, size: CGSize) {
        context.setFillColor(
            red: CGFloat(color.r)/255,
            green: CGFloat(color.g)/255,
            blue: CGFloat(color.b)/255,
            alpha: CGFloat(color.a)/255)
        triangle.drawInContext(context: context, size:size)
    }
}

public struct Color {
    public let r,g,b,a: UInt8
    public init (r: UInt8, g: UInt8, b: UInt8, a: UInt8) {
        (self.r, self.g, self.b, self.a) = (r, g, b, a)
    }
}

public struct Triangle {
    public let a: CGPoint
    public let b: CGPoint
    public let c: CGPoint
    
    public init( a: CGPoint, b: CGPoint, c: CGPoint ) {
        (self.a, self.b, self.c) = (a,b,c)
    }
    
    public func drawInContext(context: CGContext, size: CGSize) {
        //Oval(a: a,b: b).drawInContext(context: context, size: size)
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

public struct Oval {
    public let a: CGPoint
    public let b: CGPoint

    public init( a: CGPoint, b: CGPoint) {
        (self.a, self.b) = (a,b)
    }
    
    public func drawInContext(context: CGContext, size: CGSize) {
        let sA = a.scaledUnitPoint(size: size)
        let sB = b.scaledUnitPoint(size: size)

        let rect = CGRect(origin: sA, size: CGSize(width: sB.x, height: sB.y))
        context.addEllipse(in: rect)
        context.fillPath();
    }
}

public extension CGPoint {
    func scaledUnitPoint(size:CGSize) -> CGPoint {
        return CGPoint(x: self.x*size.width, y: self.y*size.height)
    }
}

//MARK: Crossover and Mutation

//TODO: Generalize finite sequence based crossover
extension Painting : Crossoverable {
    public static func cross(parent1: Painting, parent2: Painting) -> [Painting] {
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
    public static func mutate(individual:Painting) -> Painting {
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
    @inline(__always) public static func mutate(individual: Gene) -> Gene {
        let color = roll(probability: 0.1) ? Color.mutate(individual: individual.color) : Color.drift(individual: individual.color)
        let triangle = roll(probability: 0.1) ? Triangle.mutate(individual: individual.triangle) : Triangle.drift(individual: individual.triangle)
        
        return Gene(color: color, triangle: triangle)
    }
}

public extension Color {
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

public extension Triangle {
    @inline(__always) static func arbitrary() -> Triangle {
        return Triangle(a: CGPoint.randomUnit(), b: CGPoint.randomUnit(), c: CGPoint.randomUnit())
    }
}

public extension Triangle {
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

public extension CGPoint {
    @inline(__always) static func drift(individual: CGPoint) -> CGPoint {
        let op : (CGFloat, CGFloat)->CGFloat = coinFlip() ? (+) : (-)
        
        let newPoint = CGPoint(x: min(1.5,max(-0.5,op(individual.x, 0.01))), y: min(1.5,max(-0.5,op(individual.y, 0.01))))
        return newPoint
    }
}

//MARK: Rendering

public extension Painting {
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

public extension Painting {
    public static func arbitraryOfLength(length: Int) -> Painting {
        let dna : [Gene] = (0..<length).map { _ in
            return Gene.arbitrary()
        }
        
        return self.init(dna)
    }
}

public extension CGImage {
    public var size: CGSize {
        return CGSize(width: self.width, height: self.height)
    }
}

public extension Gene {
    @inline(__always) static func arbitrary() -> Gene {
        let color = Color.arbitrary()
        let triangle = Triangle.arbitrary()
        
        return self.init(color: color, triangle: triangle)
    }
}

public extension Color {
    @inline(__always) static func arbitrary() -> Color {
        return Color(r: UInt8.arbitrary(), g: UInt8.arbitrary(), b: UInt8.arbitrary(), a: UInt8.arbitrary())
    }
}

public extension UInt8 {
    @inline(__always) static func arbitrary() -> UInt8 {
        return UInt8(arc4random_uniform(UInt32(UInt8.max)))
    }
}

public extension CGFloat {
    @inline(__always) static func random(from:CGFloat, to: CGFloat) -> CGFloat {
        return from + (to-from)*(CGFloat(arc4random()) / CGFloat(UInt32.max))
    }
    
    @inline(__always) static func randomUnit() -> CGFloat {
        return self.random(from: 0, to: 1)
    }
}

public extension CGPoint {
    @inline(__always) static func random(from:CGFloat, to: CGFloat) -> CGPoint {
        return CGPoint(x: CGFloat.random(from: from, to: to), y: CGFloat.random(from: from, to: to))
    }
    
    @inline(__always) static func randomUnit() -> CGPoint {
        return self.random(from: -0.5, to: 1.5)
        //return self.random(from: 0.0, to: 1.0)
    }
}
