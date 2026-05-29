//
//  ViewController.swift
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

import UIKit

final class HiddenBadgeView: UIView {}

class ViewController: UIViewController {
    private let dogLayer = DogLayer()
    private let catView = CatView()
    private let birdView = BirdView()
    private let horseLayer = HorseLayer()
    private let viewModel0 = GoodViewModel()
    private let viewModel1 = SomeViewModel()
    
    private let label = UILabel()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        label.text = "\(Date().timeIntervalSince1970)"
        label.font = UIFont.systemFont(ofSize: 20)
        label.sizeToFit()
        view.addSubview(label)

        configureDemoAccessibility(
            on: view,
            identifier: "demo.root",
            label: "Custom Info Demo",
            hint: "Root view controller container",
            isElement: false
        )
        configureDemoAccessibility(
            on: label,
            identifier: "demo.timestampLabel",
            label: "Timestamp",
            value: label.text,
            hint: "Unix timestamp; tap anywhere to toggle label visibility",
            traits: .staticText
        )
        configureDemoAccessibility(
            on: catView,
            identifier: "demo.catView",
            label: "Cat",
            value: "Objective-C custom properties",
            hint: "Green CatView with lookin_customDebugInfos",
            traits: .image
        )
        configureDemoAccessibility(
            on: birdView,
            identifier: "demo.birdView",
            label: "Bird Jerry",
            value: "Nickname Jerry, age 4.53",
            hint: "Swift BirdView with editable custom properties",
            traits: [.button, .selected]
        )

        viewModel0.viewModelTargetView = catView
        viewModel1.viewModelTargetView = birdView

        dogLayer.backgroundColor = UIColor.blue.cgColor
        view.layer.addSublayer(dogLayer)
        dogLayer.frame = CGRect(x: 20, y: 20, width: 100, height: 100)

        catView.backgroundColor = UIColor.green
        view.addSubview(catView)
        catView.frame = CGRect(x: 20, y: 200, width: 100, height: 100)

        birdView.backgroundColor = UIColor.blue
        view.addSubview(birdView)
        birdView.frame = CGRect(x: 20, y: 400, width: 100, height: 100)

        horseLayer.backgroundColor = UIColor.orange.cgColor
        view.layer.addSublayer(horseLayer)
        horseLayer.frame = CGRect(x: 20, y: 600, width: 100, height: 100)

        let hiddenBadge = HiddenBadgeView()
        hiddenBadge.isHidden = true
        hiddenBadge.backgroundColor = UIColor.red
        hiddenBadge.frame = CGRect(x: 140, y: 20, width: 40, height: 40)
        view.addSubview(hiddenBadge)

        getLookinVersion()
        
//        let v2 = UIView()
//        v2.frame = CGRect(x: 50, y: 50, width: 50, height: 50)
//        v2.backgroundColor = .red
//        view.addSubview(v2)

//        addManyViews()
//        addNestedViews(containerView: view, level: 0)
        
//        refreshView()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        if label.superview == nil {
            view.addSubview(label)
        } else {
            label.removeFromSuperview()
        }
    }
    
//    private func refreshView() {
////        let v: UILabel
//        guard let v = view.viewWithTag(899) as? UILabel else {
//            return
//            //            oldView.removeFromSuperview()
//        }
//        
////        let v = UILabel()
//        v.text = "\(Date().timeIntervalSince1970)"
//        
//        v.alpha = CGFloat.random(in: 0.3...1.0)
//        v.font = UIFont.systemFont(ofSize: CGFloat.random(in: 14...35))
//        v.frame = CGRect(x: CGFloat(arc4random_uniform(100)) + 1, y: CGFloat(arc4random_uniform(500)) + 1, width: 0, height: 0)
//        v.sizeToFit()
//        
//        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { [weak self] in
//            self?.refreshView()
//        }
//    }
    
    private func configureDemoAccessibility(
        on view: UIView,
        identifier: String,
        label: String,
        value: String? = nil,
        hint: String? = nil,
        traits: UIAccessibilityTraits = [],
        isElement: Bool = true,
        elementsHidden: Bool = false,
        viewIsModal: Bool = false
    ) {
        view.accessibilityIdentifier = identifier
        view.accessibilityLabel = label
        view.accessibilityValue = value
        view.accessibilityHint = hint
        view.isAccessibilityElement = isElement
        view.accessibilityTraits = traits
        view.accessibilityElementsHidden = elementsHidden
        view.accessibilityViewIsModal = viewIsModal
    }

    private func getLookinVersion() {
        // NSMutableDictionary is passed by reference; Swift dictionaries are value types, so use NSMutableDictionary here.
        // NSMutableDictionary is passed by reference, while Swift's native dictionary is passed by value, so here we can only use NSMutableDictionary.
        let lookinInfos = NSMutableDictionary()
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "GetLookinInfo"), object: nil, userInfo: ["infos": lookinInfos])
        if let lookinServerVersion = lookinInfos["lookinServerVersion"] as? String {
            // Dot-separated version string, e.g. "1.2.5"
            // Here is the version number separated by decimal points, such as "1.2.5"
            print("LookinServer version: \(lookinServerVersion)")
        } else {
            // LookinServer is not integrated or its version is below 1.2.5
            print("No LookinServer. Or LookinServer version is lower than 1.2.5")
        }
    }
    
    private func addManyViews() {
        for i in 0..<500 {
            let v = UIView()
            v.frame = CGRect(x: 0, y: i, width: 1, height: 1)
            v.backgroundColor = UIColor.red
            view.addSubview(v)
        }
    }
    
    private func addNestedViews(containerView: UIView, level: Int) {
        if level >= 10 {
            return
        }
        let v = UIView()
        v.frame = containerView.bounds
        v.backgroundColor = UIColor.red
        containerView.addSubview(v)
        addNestedViews(containerView: v, level: level + 1)

        for _ in 0..<20 {
            let label = UILabel(frame: containerView.bounds)
            label.text = "fdjsoijfoisdjfioasdjiopfjsdaoijfoipsdjopifjasoipdjfoiapsjdopifjasdoipjfipjewijf9-wejf9ew8f9sd-fjdsai9jf-9adsf9ewf-9aw-f9js9-djf-9wejf-8jwe9-fae-9ejf-9sd-9fjsd-jf9-wejf-9jwe-"
            label.textColor = .blue
            containerView.addSubview(label)
        }
        
    }
}

