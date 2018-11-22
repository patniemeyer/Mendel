//
//  ViewController.swift
//  genetic
//
//  Created by Saniul Ahmed on 22/12/2014.
//  Copyright (c) 2014 Saniul Ahmed. All rights reserved.
//

import UIKit
import Mendel
import Then
import TinyConstraints

class ImageMatchingViewController: UIViewController {
    
    @IBOutlet var referenceImageView: UIImageView!
    @IBOutlet var bestIndividualImageView: UIImageView!
    @IBOutlet weak var iterationLabel: UILabel!
    @IBOutlet weak var distanceLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        testWheel()
        runImage()
    }
    
    private func testWheel()
    {
        struct Thing: IndividualType, Hashable {
            static var nextId: Int = 0
            let id: Int
            init() {
                id = Thing.nextId; Thing.nextId += 1
            }
        }
        let fitnessKind = FitnessKind.inverted
        
        var pop: [Score<Thing>] = []
        for i in 0..<50 {
            pop.append( Score<Thing>(fitness: 1.0, individual: Thing()) )
        }
        
        pop = sortEvaluatedPopulation(population: pop, fitnessKind: fitnessKind)
        
        var results = [Thing:Int]()
        let n = 100000
        for _ in 0..<n {
            let selected = Selection.rouletteWheelBroken(pop: pop, fitnessKind: fitnessKind, count: 1)[0]
            results[selected] = results[selected, default:0] + 1
        }
        for (thing,count) in results {
            let score = pop.first { $0.individual == thing }!
            print(score.fitness, Double(count)/Double(n))
        }
    }

    @IBAction func start(sender: UIButton)
    {
        runImage()
    }
    
    private func runImage()
    {
        let lab = ImageMatching()
        let url = Bundle.main.url(forResource: "mona-lisa", withExtension: "jpg")!
        let image = UIImage(named: "mona-lisa.jpg")!

        lab.referenceImageURL = url
        lab.outputImageSize = image.size
        let referenceImage = image

        let displaySize = CGSize(width: 200, height: 200)
        let referenceImageView = UIImageView().then {
            view.addSubview($0)
            $0.centerXToSuperview()
            $0.topToSuperview(offset: 4, usingSafeArea: true)
            //$0.size(referenceImage.size)
            $0.size(displaySize)
        }
        let bestIndividualImageView = UIImageView().then {
            view.addSubview($0)
            $0.centerXToSuperview()
            $0.topToBottom(of: referenceImageView, offset: 4)
            //$0.size(referenceImage.size)
            $0.size(displaySize)
        }
        let iterationLabel = UILabel().then {
            view.addSubview($0)
            $0.width(200.0)
            $0.centerXToSuperview()
            $0.topToBottom(of: bestIndividualImageView, offset: 4)
        }
        let fitnessLabel = UILabel().then {
            view.addSubview($0)
            $0.width(200.0)
            $0.centerXToSuperview()
            $0.topToBottom(of: iterationLabel, offset: 2)
        }
        let gridSide = 10
        let grid = ImageGrid(size: gridSide).then {
            view.addSubview($0)
            $0.widthToSuperview(offset: -64)
            $0.centerXToSuperview()
            $0.bottomToSuperview(offset: -4)
            $0.aspectRatio(1.0)
        }
        grid.views.forEach {
            $0.image = referenceImage
        }
        referenceImageView.image = referenceImage
        
        lab.iteration = { (data:IterationData<Painting>) in
            let image = data.bestCandidate.imageOfSize(size: referenceImage.size)
            DispatchQueue.main.async {
                bestIndividualImageView.image = UIImage(cgImage: image)
                iterationLabel.text = "Iteration: \(data.iterationNum)"
                fitnessLabel.text = "Fitness: \(String(format: "%.2f", data.bestCandidateFitness))"
                data.population.prefix(gridSide*gridSide).enumerated().forEach { i, score in
                    let view = grid.views[i]
                    let size = view.bounds.size
                    view.image = UIImage(cgImage: score.individual.imageOfSize(size: size))
                }
            }
        }
        
        DispatchQueue.global().async { () -> Void in
            //lab.run(referenceImage: referenceImage)
            lab.run()
        }
    }
}

