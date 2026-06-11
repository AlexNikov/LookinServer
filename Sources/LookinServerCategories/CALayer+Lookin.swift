#if SHOULD_COMPILE_LOOKIN_SERVER

import QuartzCore

extension CALayer {
    public func lookin_removeImplicitAnimations() {
        var actions: [String: CAAction] = [
            #keyPath(CALayer.bounds): NSNull(),
            #keyPath(CALayer.position): NSNull(),
            #keyPath(CALayer.zPosition): NSNull(),
            #keyPath(CALayer.anchorPoint): NSNull(),
            #keyPath(CALayer.anchorPointZ): NSNull(),
            #keyPath(CALayer.transform): NSNull(),
            #keyPath(CALayer.sublayerTransform): NSNull(),
            #keyPath(CALayer.masksToBounds): NSNull(),
            #keyPath(CALayer.contents): NSNull(),
            #keyPath(CALayer.contentsRect): NSNull(),
            #keyPath(CALayer.contentsScale): NSNull(),
            #keyPath(CALayer.contentsCenter): NSNull(),
            #keyPath(CALayer.minificationFilterBias): NSNull(),
            #keyPath(CALayer.backgroundColor): NSNull(),
            #keyPath(CALayer.cornerRadius): NSNull(),
            #keyPath(CALayer.borderWidth): NSNull(),
            #keyPath(CALayer.borderColor): NSNull(),
            #keyPath(CALayer.opacity): NSNull(),
            #keyPath(CALayer.compositingFilter): NSNull(),
            #keyPath(CALayer.filters): NSNull(),
            #keyPath(CALayer.backgroundFilters): NSNull(),
            #keyPath(CALayer.shouldRasterize): NSNull(),
            #keyPath(CALayer.rasterizationScale): NSNull(),
            #keyPath(CALayer.shadowColor): NSNull(),
            #keyPath(CALayer.shadowOpacity): NSNull(),
            #keyPath(CALayer.shadowOffset): NSNull(),
            #keyPath(CALayer.shadowRadius): NSNull(),
            #keyPath(CALayer.shadowPath): NSNull(),
        ]

        if self is CAShapeLayer {
            actions[#keyPath(CAShapeLayer.path)] = NSNull()
            actions[#keyPath(CAShapeLayer.fillColor)] = NSNull()
            actions[#keyPath(CAShapeLayer.strokeColor)] = NSNull()
            actions[#keyPath(CAShapeLayer.strokeStart)] = NSNull()
            actions[#keyPath(CAShapeLayer.strokeEnd)] = NSNull()
            actions[#keyPath(CAShapeLayer.lineWidth)] = NSNull()
            actions[#keyPath(CAShapeLayer.miterLimit)] = NSNull()
            actions[#keyPath(CAShapeLayer.lineDashPhase)] = NSNull()
        }

        if self is CAGradientLayer {
            actions[#keyPath(CAGradientLayer.colors)] = NSNull()
            actions[#keyPath(CAGradientLayer.locations)] = NSNull()
            actions[#keyPath(CAGradientLayer.startPoint)] = NSNull()
            actions[#keyPath(CAGradientLayer.endPoint)] = NSNull()
        }

        self.actions = actions
    }
}

#endif
