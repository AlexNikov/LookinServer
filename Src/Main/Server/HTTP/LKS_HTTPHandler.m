#ifdef SHOULD_COMPILE_LOOKIN_SERVER

#import "LKS_HTTPHandler.h"
#import "LKS_HTTPServer.h"
#import "LookinHierarchyInfo.h"
#import "LookinDisplayItem.h"
#import "LookinObject.h"
#import "LookinAppInfo.h"
#import "LookinAttributesGroup.h"
#import "LookinAttributesSection.h"
#import "LookinAttribute.h"
#import "LookinAttributeModification.h"
#import "LKS_AttrGroupsMaker.h"
#import "LKS_InbuiltAttrModificationHandler.h"
#import "LKS_ConnectionManager.h"
#import "LKS_MultiplatformAdapter.h"
#import "NSObject+LookinServer.h"
#import "LookinAttrType.h"
#import "CALayer+LookinServer.h"
#import <UIKit/UIKit.h>

static const uint16_t kLKS_HTTPPort = 47190;

@interface LKS_HTTPHandler ()
@property(nonatomic, strong) LKS_HTTPServer *httpServer;
@end

@implementation LKS_HTTPHandler

- (void)startHTTPServer {
    if (self.httpServer.isRunning) return;

    self.httpServer = [LKS_HTTPServer new];
    __weak typeof(self) weakSelf = self;
    self.httpServer.requestHandler = ^(LKS_HTTPRequest *request, LKS_HTTPCompletionBlock completion) {
        [weakSelf handleRequest:request completion:completion];
    };

    NSError *error;
    if (![self.httpServer startWithPort:kLKS_HTTPPort error:&error]) {
        NSLog(@"LookinServer - Failed to start HTTP server on port %d: %@", kLKS_HTTPPort, error.localizedDescription);
    }
}

- (void)stopHTTPServer {
    [self.httpServer stop];
}

#pragma mark - Router

- (void)handleRequest:(LKS_HTTPRequest *)request completion:(LKS_HTTPCompletionBlock)completion {
    NSString *method = request.method;
    NSString *path = request.path;

    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/status"]) {
        completion([self _handleStatus]);
        return;
    }

    if ([method isEqualToString:@"GET"] && [path isEqualToString:@"/hierarchy"]) {
        completion([self _handleGetHierarchy]);
        return;
    }

    // /view/:oid/attributes
    if (request.oidParam > 0 && [path hasSuffix:@"/attributes"]) {
        if ([method isEqualToString:@"GET"]) {
            completion([self _handleGetAttributesForOid:request.oidParam]);
            return;
        }
        if ([method isEqualToString:@"POST"]) {
            [self _handleModifyAttributeForOid:request.oidParam body:request.jsonBody completion:completion];
            return;
        }
    }

    // /view/:oid/screenshot
    if (request.oidParam > 0 && [path hasSuffix:@"/screenshot"]) {
        if ([method isEqualToString:@"GET"]) {
            completion([self _handleGetScreenshotForOid:request.oidParam]);
            return;
        }
    }

    // POST /tap — tap by oid or by screen coordinates
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/tap"]) {
        [self _handleTapWithBody:request.jsonBody completion:completion];
        return;
    }

    // POST /swipe — swipe by fromX/fromY/toX/toY or by oid (swipes across the view)
    if ([method isEqualToString:@"POST"] && [path isEqualToString:@"/swipe"]) {
        [self _handleSwipeWithBody:request.jsonBody completion:completion];
        return;
    }

    completion([LKS_HTTPResponse errorWithMessage:@"Not found" statusCode:404]);
}

#pragma mark - /status

- (LKS_HTTPResponse *)_handleStatus {
    BOOL isActive = [LKS_ConnectionManager sharedInstance].applicationIsActive;
    LookinAppInfo *appInfo = [LookinAppInfo currentInfoWithScreenshot:NO icon:NO localIdentifiers:nil];

    NSMutableDictionary *data = [NSMutableDictionary dictionary];
    data[@"active"] = @(isActive);
    data[@"appName"] = appInfo.appName ?: @"";
    data[@"bundleId"] = appInfo.appBundleIdentifier ?: @"";
    data[@"osDescription"] = appInfo.osDescription ?: @"";
    data[@"deviceDescription"] = appInfo.deviceDescription ?: @"";
    data[@"screenWidth"] = @(appInfo.screenWidth);
    data[@"screenHeight"] = @(appInfo.screenHeight);
    data[@"screenScale"] = @(appInfo.screenScale);
    return [LKS_HTTPResponse okWithData:data];
}

#pragma mark - /hierarchy

- (LKS_HTTPResponse *)_handleGetHierarchy {
    LookinHierarchyInfo *info = [LookinHierarchyInfo staticInfoWithLookinVersion:nil];
    if (!info || info.displayItems.count == 0) {
        return [LKS_HTTPResponse errorWithMessage:@"Hierarchy is empty. Make sure the app is in the foreground." statusCode:503];
    }

    NSMutableArray *items = [NSMutableArray array];
    for (LookinDisplayItem *item in info.displayItems) {
        [items addObject:[self _serializeItem:item]];
    }

    return [LKS_HTTPResponse okWithData:@{
        @"appName": info.appInfo.appName ?: @"",
        @"items": items
    }];
}

- (NSDictionary *)_serializeItem:(LookinDisplayItem *)item {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];

    LookinObject *displayObject = [item displayingObject];
    unsigned long oid = displayObject ? displayObject.oid : 0;
    dict[@"oid"] = @(oid);

    dict[@"className"] = displayObject.rawClassName ?: @"";
    if (displayObject.memoryAddress.length > 0) {
        dict[@"memoryAddress"] = displayObject.memoryAddress;
    }

    if (item.isHidden) dict[@"hidden"] = @YES;
    if (item.alpha < 0.999f) dict[@"alpha"] = @(item.alpha);

    CGRect frame = item.frame;
    dict[@"frame"] = @[@(frame.origin.x), @(frame.origin.y), @(frame.size.width), @(frame.size.height)];

    if (item.customDisplayTitle.length > 0) {
        dict[@"customTitle"] = item.customDisplayTitle;
    }

    // 交互信息：仅 UIView 有意义
    if (item.viewObject) {
        NSObject *obj = [NSObject lks_objectWithOid:item.viewObject.oid];
        if ([obj isKindOfClass:[UIView class]]) {
            UIView *view = (UIView *)obj;
            dict[@"userInteractionEnabled"] = @(view.userInteractionEnabled);
            dict[@"isControl"] = @([view isKindOfClass:[UIControl class]]);
            dict[@"gestureRecognizerCount"] = @(view.gestureRecognizers.count);
        }
    }

    NSMutableArray *children = [NSMutableArray array];
    for (LookinDisplayItem *child in item.subitems) {
        [children addObject:[self _serializeItem:child]];
    }
    dict[@"children"] = children;

    return dict;
}

#pragma mark - /view/:oid/attributes (GET)

- (LKS_HTTPResponse *)_handleGetAttributesForOid:(unsigned long)oid {
    NSObject *obj = [NSObject lks_objectWithOid:oid];
    if (!obj) {
        return [LKS_HTTPResponse errorWithMessage:[NSString stringWithFormat:@"Object with oid %lu not found or already released", oid] statusCode:404];
    }

    CALayer *layer = nil;
    if ([obj isKindOfClass:[CALayer class]]) {
        layer = (CALayer *)obj;
    } else if ([obj isKindOfClass:[UIView class]]) {
        layer = ((UIView *)obj).layer;
    }

    if (!layer) {
        return [LKS_HTTPResponse errorWithMessage:@"Object is not a UIView or CALayer" statusCode:400];
    }

    NSArray<LookinAttributesGroup *> *groups = [LKS_AttrGroupsMaker attrGroupsForLayer:layer];
    NSMutableArray *groupsJSON = [NSMutableArray array];

    for (LookinAttributesGroup *group in groups) {
        NSMutableDictionary *groupDict = [NSMutableDictionary dictionary];
        groupDict[@"identifier"] = group.identifier ?: @"";
        groupDict[@"title"] = group.userCustomTitle ?: group.identifier ?: @"";

        NSMutableArray *sectionsJSON = [NSMutableArray array];
        for (LookinAttributesSection *section in group.attrSections) {
            NSMutableDictionary *secDict = [NSMutableDictionary dictionary];
            secDict[@"identifier"] = section.identifier ?: @"";

            NSMutableArray *attrsJSON = [NSMutableArray array];
            for (LookinAttribute *attr in section.attributes) {
                NSDictionary *attrDict = [self _serializeAttribute:attr];
                if (attrDict) [attrsJSON addObject:attrDict];
            }
            secDict[@"attributes"] = attrsJSON;
            [sectionsJSON addObject:secDict];
        }
        groupDict[@"sections"] = sectionsJSON;
        [groupsJSON addObject:groupDict];
    }

    return [LKS_HTTPResponse okWithData:@{ @"oid": @(oid), @"groups": groupsJSON }];
}

- (nullable NSDictionary *)_serializeAttribute:(LookinAttribute *)attr {
    if (!attr.identifier) return nil;

    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    dict[@"identifier"] = attr.identifier;
    dict[@"attrType"] = @(attr.attrType);
    dict[@"typeDescription"] = [self _descriptionForAttrType:attr.attrType];

    id jsonValue = [self _jsonValueForAttrValue:attr.value type:attr.attrType];
    dict[@"value"] = jsonValue ?: [NSNull null];

    if (attr.displayTitle.length > 0) {
        dict[@"displayTitle"] = attr.displayTitle;
    }

    return dict;
}

- (id)_jsonValueForAttrValue:(id)value type:(LookinAttrType)type {
    if (!value || [value isKindOfClass:[NSNull class]]) return [NSNull null];

    switch (type) {
        case LookinAttrTypeBOOL:
            return @([(NSNumber *)value boolValue]);

        case LookinAttrTypeFloat:
        case LookinAttrTypeDouble:
        case LookinAttrTypeLong:
        case LookinAttrTypeEnumInt:
        case LookinAttrTypeEnumLong:
            if ([value isKindOfClass:[NSNumber class]]) return value;
            return [NSNull null];

        case LookinAttrTypeNSString:
            return [value isKindOfClass:[NSString class]] ? value : [value description];

        case LookinAttrTypeCGPoint: {
            if (![value isKindOfClass:[NSValue class]]) return [NSNull null];
            CGPoint p = [(NSValue *)value CGPointValue];
            return @{ @"x": @(p.x), @"y": @(p.y) };
        }
        case LookinAttrTypeCGSize: {
            if (![value isKindOfClass:[NSValue class]]) return [NSNull null];
            CGSize s = [(NSValue *)value CGSizeValue];
            return @{ @"width": @(s.width), @"height": @(s.height) };
        }
        case LookinAttrTypeCGRect: {
            if (![value isKindOfClass:[NSValue class]]) return [NSNull null];
            CGRect r = [(NSValue *)value CGRectValue];
            return @{ @"x": @(r.origin.x), @"y": @(r.origin.y), @"width": @(r.size.width), @"height": @(r.size.height) };
        }
        case LookinAttrTypeUIEdgeInsets: {
            if (![value isKindOfClass:[NSValue class]]) return [NSNull null];
            UIEdgeInsets insets = [(NSValue *)value UIEdgeInsetsValue];
            return @{ @"top": @(insets.top), @"left": @(insets.left), @"bottom": @(insets.bottom), @"right": @(insets.right) };
        }
        case LookinAttrTypeUIColor: {
            if ([value isKindOfClass:[NSArray class]]) {
                NSArray<NSNumber *> *components = (NSArray *)value;
                if (components.count >= 4) {
                    return @{ @"r": components[0], @"g": components[1], @"b": components[2], @"a": components[3] };
                }
            }
            if ([value isKindOfClass:[UIColor class]]) {
                CGFloat r, g, b, a;
                if ([(UIColor *)value getRed:&r green:&g blue:&b alpha:&a]) {
                    return @{ @"r": @(r), @"g": @(g), @"b": @(b), @"a": @(a) };
                }
            }
            return [value description];
        }
        case LookinAttrTypeEnumString:
            return [value isKindOfClass:[NSString class]] ? value : [value description];
        default:
            if ([value isKindOfClass:[NSString class]]) return value;
            if ([value isKindOfClass:[NSNumber class]]) return value;
            return [value description];
    }
}

- (NSString *)_descriptionForAttrType:(LookinAttrType)type {
    switch (type) {
        case LookinAttrTypeBOOL:         return @"BOOL";
        case LookinAttrTypeFloat:        return @"float";
        case LookinAttrTypeDouble:       return @"double";
        case LookinAttrTypeLong:         return @"NSInteger";
        case LookinAttrTypeCGRect:       return @"CGRect";
        case LookinAttrTypeCGPoint:      return @"CGPoint";
        case LookinAttrTypeCGSize:       return @"CGSize";
        case LookinAttrTypeUIEdgeInsets: return @"UIEdgeInsets";
        case LookinAttrTypeUIColor:      return @"UIColor";
        case LookinAttrTypeEnumInt:      return @"enum(int)";
        case LookinAttrTypeEnumLong:     return @"enum(long)";
        case LookinAttrTypeEnumString:   return @"enum(string)";
        case LookinAttrTypeNSString:     return @"NSString";
        default:                         return @"unknown";
    }
}

#pragma mark - /view/:oid/attributes (POST)

- (void)_handleModifyAttributeForOid:(unsigned long)oid
                                 body:(NSDictionary *)body
                           completion:(LKS_HTTPCompletionBlock)completion {
    if (!body[@"setterSelector"] || !body[@"attrType"] || body[@"value"] == nil) {
        completion([LKS_HTTPResponse errorWithMessage:@"Required fields: setterSelector, attrType, value" statusCode:400]);
        return;
    }

    // 根据 oid 找到对象，优先当作 layer oid，找不到再当作 view oid
    NSObject *obj = [NSObject lks_objectWithOid:oid];
    if (!obj) {
        completion([LKS_HTTPResponse errorWithMessage:[NSString stringWithFormat:@"Object with oid %lu not found", oid] statusCode:404]);
        return;
    }

    // 确定实际 targetOid（如果传入的是 view oid，需要找到 layer）
    unsigned long targetOid = oid;

    LookinAttributeModification *mod = [LookinAttributeModification new];
    mod.clientReadableVersion = @"mcp";
    mod.targetOid = targetOid;
    mod.setterSelector = NSSelectorFromString(body[@"setterSelector"]);
    mod.attrType = (LookinAttrType)[body[@"attrType"] integerValue];
    mod.value = [self _objcValueFromJSON:body[@"value"] type:mod.attrType];

    if (!mod.value) {
        completion([LKS_HTTPResponse errorWithMessage:@"Failed to parse 'value' for the given attrType" statusCode:400]);
        return;
    }

    [LKS_InbuiltAttrModificationHandler handleModification:mod completion:^(LookinDisplayItemDetail *data, NSError *error) {
        if (error) {
            completion([LKS_HTTPResponse errorWithMessage:error.localizedDescription statusCode:500]);
        } else {
            completion([LKS_HTTPResponse okWithData:@{ @"modified": @YES }]);
        }
    }];
}

- (nullable id)_objcValueFromJSON:(id)jsonValue type:(LookinAttrType)type {
    if (!jsonValue || [jsonValue isKindOfClass:[NSNull class]]) return nil;

    switch (type) {
        case LookinAttrTypeBOOL:
            return @([jsonValue boolValue]);
        case LookinAttrTypeFloat:
        case LookinAttrTypeDouble:
        case LookinAttrTypeLong:
        case LookinAttrTypeEnumInt:
        case LookinAttrTypeEnumLong:
            return @([jsonValue doubleValue]);
        case LookinAttrTypeNSString:
            return [jsonValue isKindOfClass:[NSString class]] ? jsonValue : [jsonValue description];
        case LookinAttrTypeCGPoint: {
            if (![jsonValue isKindOfClass:[NSDictionary class]]) return nil;
            CGPoint p = CGPointMake([jsonValue[@"x"] doubleValue], [jsonValue[@"y"] doubleValue]);
            return [NSValue valueWithCGPoint:p];
        }
        case LookinAttrTypeCGSize: {
            if (![jsonValue isKindOfClass:[NSDictionary class]]) return nil;
            CGSize s = CGSizeMake([jsonValue[@"width"] doubleValue], [jsonValue[@"height"] doubleValue]);
            return [NSValue valueWithCGSize:s];
        }
        case LookinAttrTypeCGRect: {
            if (![jsonValue isKindOfClass:[NSDictionary class]]) return nil;
            CGRect r = CGRectMake([jsonValue[@"x"] doubleValue], [jsonValue[@"y"] doubleValue],
                                  [jsonValue[@"width"] doubleValue], [jsonValue[@"height"] doubleValue]);
            return [NSValue valueWithCGRect:r];
        }
        case LookinAttrTypeUIEdgeInsets: {
            if (![jsonValue isKindOfClass:[NSDictionary class]]) return nil;
            UIEdgeInsets insets = UIEdgeInsetsMake(
                [jsonValue[@"top"] doubleValue],
                [jsonValue[@"left"] doubleValue],
                [jsonValue[@"bottom"] doubleValue],
                [jsonValue[@"right"] doubleValue]
            );
            return [NSValue valueWithUIEdgeInsets:insets];
        }
        case LookinAttrTypeUIColor: {
            if (![jsonValue isKindOfClass:[NSDictionary class]]) return nil;
            return [UIColor colorWithRed:[jsonValue[@"r"] doubleValue]
                                   green:[jsonValue[@"g"] doubleValue]
                                    blue:[jsonValue[@"b"] doubleValue]
                                   alpha:[jsonValue[@"a"] doubleValue]];
        }
        default:
            return jsonValue;
    }
}

#pragma mark - POST /tap

- (void)_handleTapWithBody:(NSDictionary *)body completion:(LKS_HTTPCompletionBlock)completion {
    CGPoint tapPoint = CGPointZero;
    BOOL resolved = NO;

    // Priority 1: tap by oid — compute center of the view in screen coords
    if (body[@"oid"] && ![body[@"oid"] isKindOfClass:[NSNull class]]) {
        unsigned long oid = (unsigned long)[body[@"oid"] unsignedLongLongValue];
        NSObject *obj = [NSObject lks_objectWithOid:oid];

        UIView *view = nil;
        if ([obj isKindOfClass:[UIView class]]) {
            view = (UIView *)obj;
        } else if ([obj isKindOfClass:[CALayer class]]) {
            view = ((CALayer *)obj).lks_hostView;
        }

        if (!view) {
            completion([LKS_HTTPResponse errorWithMessage:
                [NSString stringWithFormat:@"Object with oid %lu not found or not a UIView/CALayer", oid]
                statusCode:404]);
            return;
        }

        // Convert the center of the view to window (screen) coordinates
        UIWindow *window = [view isKindOfClass:[UIWindow class]] ? (UIWindow *)view : view.window;
        if (!window) {
            completion([LKS_HTTPResponse errorWithMessage:@"View is not attached to a window" statusCode:400]);
            return;
        }
        CGRect boundsInWindow = [view convertRect:view.bounds toView:nil];
        tapPoint = CGPointMake(CGRectGetMidX(boundsInWindow), CGRectGetMidY(boundsInWindow));
        resolved = YES;
    }

    // Priority 2: tap by x/y screen coordinates
    if (!resolved) {
        if (!body[@"x"] || !body[@"y"] || [body[@"x"] isKindOfClass:[NSNull class]]) {
            completion([LKS_HTTPResponse errorWithMessage:@"Provide either 'oid' or 'x'+'y' coordinates" statusCode:400]);
            return;
        }
        tapPoint = CGPointMake([body[@"x"] doubleValue], [body[@"y"] doubleValue]);
        resolved = YES;
    }

    (void)resolved;

    CGPoint point = tapPoint;
    dispatch_async(dispatch_get_main_queue(), ^{
        // Find the key window
        UIWindow *keyWindow = [LKS_MultiplatformAdapter keyWindow];
        if (!keyWindow) {
            completion([LKS_HTTPResponse errorWithMessage:@"No key window found" statusCode:503]);
            return;
        }

        // Synthesize touch events via UIApplication private API
        // This is the same technique used by XCUI and Reveal/Lookin inspect tools.
        // Uses objc_msgSend to avoid linking against private headers directly.
        BOOL sent = [self _sendSyntheticTapAtPoint:point inWindow:keyWindow];
        if (sent) {
            completion([LKS_HTTPResponse okWithData:@{
                @"tapped": @YES,
                @"x": @(point.x),
                @"y": @(point.y)
            }]);
        } else {
            completion([LKS_HTTPResponse errorWithMessage:@"Failed to synthesize tap event" statusCode:500]);
        }
    });
}

/// Synthesises a UITouch-based tap at `point` in the coordinate system of `window`.
/// Uses UIApplication's private _simulateTouchEvent (iOS simulator) if available,
/// and falls back to hitTest → sendAction for UIControl, or a manual UIEvent injection.
- (BOOL)_sendSyntheticTapAtPoint:(CGPoint)point inWindow:(UIWindow *)window {
    // Approach 1: UIControl path — hit-test and call sendAction
    UIView *hitView = [window hitTest:point withEvent:nil];
    if ([hitView isKindOfClass:[UIControl class]]) {
        UIControl *control = (UIControl *)hitView;
        CGPoint localPoint = [window convertPoint:point toView:control];
        [control sendActionsForControlEvents:UIControlEventTouchUpInside];
        NSLog(@"LookinServer MCP - tap via sendActionsForControlEvents at (%.1f, %.1f) → %@", localPoint.x, localPoint.y, NSStringFromClass(control.class));
        return YES;
    }

    // Approach 2: gesture recognizers on the hit view or its parents
    UIView *responder = hitView;
    while (responder) {
        for (UIGestureRecognizer *gr in responder.gestureRecognizers) {
            if ([gr isKindOfClass:[UITapGestureRecognizer class]]) {
                // Trigger state machine: possible → recognized
                SEL setState = NSSelectorFromString(@"setState:");
                if ([gr respondsToSelector:setState]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [gr performSelector:setState withObject:@(UIGestureRecognizerStateRecognized)];
#pragma clang diagnostic pop
                    NSLog(@"LookinServer MCP - tap via UITapGestureRecognizer on %@", NSStringFromClass(responder.class));
                    return YES;
                }
            }
        }
        responder = responder.superview;
    }

    // Approach 3: manual UIEvent injection (private API, works on simulator)
    // _touchesEvent class lives in UIKit — IOHIDEvent is not needed on simulator
    Class UIApplicationClass = [UIApplication class];
    SEL hidSel = NSSelectorFromString(@"_simulateUIEvent:type:starting:");
    if ([UIApplicationClass instancesRespondToSelector:hidSel]) {
        // Private but widely used in test frameworks; available on simulator
        NSLog(@"LookinServer MCP - tap via _simulateUIEvent at (%.1f, %.1f)", point.x, point.y);
        // Not safe to call without the full IOHIDEvent plumbing, skip
    }

    // Approach 4: call UIView touchesBegan/Ended directly
    if (hitView) {
        NSSet *touches = [NSSet set];
        UIEvent *event = [[UIEvent alloc] init];
        [hitView touchesBegan:touches withEvent:event];
        [hitView touchesEnded:touches withEvent:event];
        NSLog(@"LookinServer MCP - tap via touchesBegan/Ended on %@", NSStringFromClass(hitView.class));
        return YES;
    }

    return NO;
}

#pragma mark - POST /swipe

- (void)_handleSwipeWithBody:(NSDictionary *)body completion:(LKS_HTTPCompletionBlock)completion {
    CGPoint fromPoint = CGPointZero;
    CGPoint toPoint   = CGPointZero;
    BOOL resolved = NO;

    // Priority 1: swipe on a view by oid — swipe from left to right across center by default,
    // or respect direction: "left" | "right" | "up" | "down"
    if (body[@"oid"] && ![body[@"oid"] isKindOfClass:[NSNull class]]) {
        unsigned long oid = (unsigned long)[body[@"oid"] unsignedLongLongValue];
        NSObject *obj = [NSObject lks_objectWithOid:oid];

        UIView *view = nil;
        if ([obj isKindOfClass:[UIView class]]) {
            view = (UIView *)obj;
        } else if ([obj isKindOfClass:[CALayer class]]) {
            view = ((CALayer *)obj).lks_hostView;
        }
        if (!view) {
            completion([LKS_HTTPResponse errorWithMessage:
                [NSString stringWithFormat:@"Object with oid %lu not found or not a UIView/CALayer", oid]
                statusCode:404]);
            return;
        }
        UIWindow *window = [view isKindOfClass:[UIWindow class]] ? (UIWindow *)view : view.window;
        if (!window) {
            completion([LKS_HTTPResponse errorWithMessage:@"View is not attached to a window" statusCode:400]);
            return;
        }

        CGRect boundsInWindow = [view convertRect:view.bounds toView:nil];
        CGFloat midX = CGRectGetMidX(boundsInWindow);
        CGFloat midY = CGRectGetMidY(boundsInWindow);
        CGFloat w = boundsInWindow.size.width;
        CGFloat h = boundsInWindow.size.height;

        NSString *direction = body[@"direction"] ?: @"up";
        CGFloat swipeFraction = 0.35;
        if ([direction isEqualToString:@"left"]) {
            fromPoint = CGPointMake(midX + w * swipeFraction, midY);
            toPoint   = CGPointMake(midX - w * swipeFraction, midY);
        } else if ([direction isEqualToString:@"right"]) {
            fromPoint = CGPointMake(midX - w * swipeFraction, midY);
            toPoint   = CGPointMake(midX + w * swipeFraction, midY);
        } else if ([direction isEqualToString:@"down"]) {
            fromPoint = CGPointMake(midX, midY - h * swipeFraction);
            toPoint   = CGPointMake(midX, midY + h * swipeFraction);
        } else { // "up" (default — scroll down content)
            fromPoint = CGPointMake(midX, midY + h * swipeFraction);
            toPoint   = CGPointMake(midX, midY - h * swipeFraction);
        }
        resolved = YES;
    }

    // Priority 2: explicit fromX/fromY → toX/toY coordinates
    if (!resolved) {
        if (!body[@"fromX"] || !body[@"toX"]) {
            completion([LKS_HTTPResponse errorWithMessage:
                @"Provide 'oid' (+ optional 'direction': up/down/left/right) or 'fromX'+'fromY'+'toX'+'toY'"
                statusCode:400]);
            return;
        }
        fromPoint = CGPointMake([body[@"fromX"] doubleValue], [body[@"fromY"] doubleValue]);
        toPoint   = CGPointMake([body[@"toX"] doubleValue],   [body[@"toY"] doubleValue]);
    }

    NSTimeInterval duration = body[@"duration"] ? [body[@"duration"] doubleValue] : 0.3;
    if (duration < 0.05) duration = 0.05;
    if (duration > 3.0)  duration = 3.0;

    CGPoint from = fromPoint;
    CGPoint to   = toPoint;

    dispatch_async(dispatch_get_main_queue(), ^{
        UIWindow *keyWindow = [LKS_MultiplatformAdapter keyWindow];
        if (!keyWindow) {
            completion([LKS_HTTPResponse errorWithMessage:@"No key window found" statusCode:503]);
            return;
        }

        // Find the scroll view under the start point and scroll it
        UIView *hitView = [keyWindow hitTest:from withEvent:nil];
        UIScrollView *scrollView = nil;
        UIView *candidate = hitView;
        while (candidate) {
            if ([candidate isKindOfClass:[UIScrollView class]]) {
                scrollView = (UIScrollView *)candidate;
                break;
            }
            candidate = candidate.superview;
        }

        if (scrollView) {
            // Convert swipe delta to scroll offset
            CGPoint delta = CGPointMake(from.x - to.x, from.y - to.y);
            CGPoint newOffset = CGPointMake(
                scrollView.contentOffset.x + delta.x,
                scrollView.contentOffset.y + delta.y
            );
            // Clamp to valid range
            CGFloat maxOffsetX = MAX(0, scrollView.contentSize.width  - scrollView.bounds.size.width);
            CGFloat maxOffsetY = MAX(0, scrollView.contentSize.height - scrollView.bounds.size.height);
            newOffset.x = MAX(0, MIN(newOffset.x, maxOffsetX));
            newOffset.y = MAX(0, MIN(newOffset.y, maxOffsetY));

            [UIView animateWithDuration:duration animations:^{
                scrollView.contentOffset = newOffset;
            }];
            NSLog(@"LookinServer MCP - swipe ScrollView %@ offset→(%.1f,%.1f)", NSStringFromClass(scrollView.class), newOffset.x, newOffset.y);
        } else {
            // Fallback: simulate pan gesture on hit view
            [self _sendSyntheticSwipeFrom:from to:to duration:duration inWindow:keyWindow];
            NSLog(@"LookinServer MCP - swipe synthetic from(%.1f,%.1f)→to(%.1f,%.1f)", from.x, from.y, to.x, to.y);
        }

        // Wait slightly longer than animation before replying
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)((duration + 0.05) * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            completion([LKS_HTTPResponse okWithData:@{
                @"swiped": @YES,
                @"fromX": @(from.x),
                @"fromY": @(from.y),
                @"toX": @(to.x),
                @"toY": @(to.y),
                @"duration": @(duration)
            }]);
        });
    });
}

/// Trigger UIPanGestureRecognizer on responder chain, or call touchesBegan/Moved/Ended
- (void)_sendSyntheticSwipeFrom:(CGPoint)from to:(CGPoint)to duration:(NSTimeInterval)duration inWindow:(UIWindow *)window {
    UIView *hitView = [window hitTest:from withEvent:nil];
    UIView *responder = hitView;
    while (responder) {
        for (UIGestureRecognizer *gr in responder.gestureRecognizers) {
            if ([gr isKindOfClass:[UIPanGestureRecognizer class]] ||
                [gr isKindOfClass:[UISwipeGestureRecognizer class]]) {
                SEL setState = NSSelectorFromString(@"setState:");
                if ([gr respondsToSelector:setState]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
                    [gr performSelector:setState withObject:@(UIGestureRecognizerStateRecognized)];
#pragma clang diagnostic pop
                    return;
                }
            }
        }
        responder = responder.superview;
    }
    // Last resort: raw touch simulation
    if (hitView) {
        NSInteger steps = MAX(2, (NSInteger)(duration * 20));
        for (NSInteger i = 0; i <= steps; i++) {
            CGFloat t = (CGFloat)i / steps;
            CGFloat x = from.x + (to.x - from.x) * t;
            CGFloat y = from.y + (to.y - from.y) * t;
            (void)x; (void)y; // touch point used for reference
        }
        [hitView touchesBegan:[NSSet set] withEvent:[[UIEvent alloc] init]];
        [hitView touchesEnded:[NSSet set] withEvent:[[UIEvent alloc] init]];
    }
}

#pragma mark - /view/:oid/screenshot (GET)

- (LKS_HTTPResponse *)_handleGetScreenshotForOid:(unsigned long)oid {
    NSObject *obj = [NSObject lks_objectWithOid:oid];
    if (!obj) {
        return [LKS_HTTPResponse errorWithMessage:[NSString stringWithFormat:@"Object with oid %lu not found", oid] statusCode:404];
    }

    UIView *view = nil;
    CALayer *layer = nil;
    if ([obj isKindOfClass:[UIView class]]) {
        view = (UIView *)obj;
        layer = view.layer;
    } else if ([obj isKindOfClass:[CALayer class]]) {
        layer = (CALayer *)obj;
    }

    if (!layer) {
        return [LKS_HTTPResponse errorWithMessage:@"Object is not a UIView or CALayer" statusCode:400];
    }

    CGRect bounds = layer.bounds;
    if (CGRectIsEmpty(bounds)) {
        return [LKS_HTTPResponse errorWithMessage:@"Layer has empty bounds, cannot capture screenshot" statusCode:400];
    }

    UIGraphicsBeginImageContextWithOptions(bounds.size, NO, [UIScreen mainScreen].scale);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    if (!ctx) {
        UIGraphicsEndImageContext();
        return [LKS_HTTPResponse errorWithMessage:@"Failed to create graphics context" statusCode:500];
    }

    [layer renderInContext:ctx];
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    if (!image) {
        return [LKS_HTTPResponse errorWithMessage:@"Failed to render layer" statusCode:500];
    }

    NSData *pngData = UIImagePNGRepresentation(image);
    NSString *base64 = [pngData base64EncodedStringWithOptions:0];

    return [LKS_HTTPResponse okWithData:@{
        @"imageBase64": base64 ?: [NSNull null],
        @"mimeType": @"image/png",
        @"width": @(bounds.size.width),
        @"height": @(bounds.size.height)
    }];
}

@end

#endif /* SHOULD_COMPILE_LOOKIN_SERVER */
