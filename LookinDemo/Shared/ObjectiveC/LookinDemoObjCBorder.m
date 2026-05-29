//
//  LookinDemoObjCBorder.m
//  LookinDemo
//

#import "LookinDemoObjCBorder.h"
#import <objc/runtime.h>

void LookinDemoApplyObjCRootViewGreenBorder(UIView *view) {
    if (!view) {
        return;
    }
    view.layer.borderWidth = 4;
}

static UIViewController *LookinDemoVisibleRootViewController(UIWindow *window) {
    UIViewController *vc = window.rootViewController;
    while (vc.presentedViewController) {
        vc = vc.presentedViewController;
    }
    if ([vc isKindOfClass:[UINavigationController class]]) {
        UINavigationController *nav = (UINavigationController *)vc;
        return nav.visibleViewController ?: nav;
    }
    if ([vc isKindOfClass:[UITabBarController class]]) {
        UITabBarController *tab = (UITabBarController *)vc;
        vc = tab.selectedViewController;
        if ([vc isKindOfClass:[UINavigationController class]]) {
            UINavigationController *nav = (UINavigationController *)vc;
            return nav.visibleViewController ?: nav;
        }
        return vc;
    }
    return vc;
}

@implementation UIViewController (LookinDemoObjCBorder)

+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class cls = [UIViewController class];
        SEL originalSEL = @selector(viewDidAppear:);
        SEL swizzledSEL = @selector(lookin_demoObjCBorder_viewDidAppear:);
        Method originalMethod = class_getInstanceMethod(cls, originalSEL);
        Method swizzledMethod = class_getInstanceMethod(cls, swizzledSEL);
        if (originalMethod && swizzledMethod) {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}

- (void)lookin_demoObjCBorder_viewDidAppear:(BOOL)animated {
    [self lookin_demoObjCBorder_viewDidAppear:animated];
    UIWindow *window = self.viewIfLoaded.window;
    if (!window) {
        return;
    }
    if (LookinDemoVisibleRootViewController(window) != self) {
        return;
    }
    LookinDemoApplyObjCRootViewGreenBorder(self.view);
}

@end
