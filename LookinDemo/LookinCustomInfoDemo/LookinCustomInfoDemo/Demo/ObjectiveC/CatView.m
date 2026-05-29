//
//  CatView.m
//  LookinDemoOC
//
//  Maintained by Cursor Agent.
//

#import "CatView.h"
#import <UIKit/UIKit.h>

@interface CatView ()

@end

@implementation CatView

- (instancetype)init
{
    self = [super init];
    if (self) {
    }
    return self;
}

/// Implement this method to expose custom properties in Lookin
/// Check whether a parent, child, or category already implements this method. To avoid conflicts, rename it to lookin_customDebugInfos_0 (the trailing 0 may be 0–5).
/// Lookin calls this on every refresh; keep it fast to avoid slowing down inspection.
///
/// Implement this method to display custom properties in Lookin.
/// Please note if this method has already been implemented by the superclass, subclass, or category. If so, to avoid conflicts, you can rename this method to lookin_customDebugInfos_0 (the trailing number 0 can be replaced with any number from 0 to 5).
/// This method is called every time Lookin refreshes, so if this method takes a long time to execute, it will slow down the refresh speed.
///
/// https://bytedance.feishu.cn/docx/TRridRXeUoErMTxs94bcnGchnlb
- (NSDictionary<NSString *, id> *)lookin_customDebugInfos {
    NSDictionary<NSString *, id> *ret = @{
        // Optional. Shown in Lookin's right-hand attribute panel.
        // Optional. These details will be displayed in the right-hand property panel of Lookin.
        @"properties": [self catView_makeCustomProperties],
        // Optional. Shown in Lookin's left hierarchy panel.
        // Optional. This information will be displayed in the layer structure on the left side of Lookin.
        @"subviews": [self catView_makeCustomSubviews],
        // Optional. Display name for this view in the hierarchy tree.
        // Optional. The name of the view instance in the hierarchy panel on the left side of Lookin.
        @"title": @"CustomCatView",
        // Optional. Reserved for the DanceUI team; ignore otherwise.
        // Optional. Reserved fields for the DanceUI project team, please ignore if you are not part of the team.
        @"lookin_source": [self createDanceUIJson],
    };
    return ret;
}

- (NSArray *)catView_makeCustomProperties {
    NSMutableArray *properties = [NSMutableArray array];
    
    // See DogLayer.m for more property type examples.
    // See DogLayer.m for more examples
    [properties addObject:@{
        @"section": @"CatInfo",
        @"title": @"Age",
        @"value": [NSNumber numberWithDouble:8],
        @"valueType": @"number",
        @"retainedSetter": ^(NSNumber *newNumber) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    return [properties copy];
}

- (NSArray *)catView_makeCustomSubviews {
    NSMutableArray *subviews = [NSMutableArray array];
    
    [subviews addObject:@{
        // Required. Element title shown in Lookin.
        // Required. The name of the element displayed in Lookin.
        @"title": @"Fake Cat Subview",
        // Optional. Element subtitle shown in Lookin.
        // Optional. The subtitle of the element displayed in Lookin.
        @"subtitle": @"Nice Baby",
        // Optional. When set, Lookin draws an outline in the preview. Rect is window-relative, not parent-relative.
        // Optional. If this item is included, Lookin will display a wireframe in the middle image area. The Rect here is relative to the current Window (not relative to the parent element).
        @"frameInWindow": [NSValue valueWithCGRect:CGRectMake(100, 100, 200, 300)],
        // Optional. Shown in the right panel; field format matches catView_makeCustomProperties above.
        // Optional. This information will be displayed in the right-hand panel of Lookin, with field formatting as described in the catView_makeCustomProperties method above.
        @"properties": @[
            @{
                @"section": @"CatInfo",
                @"title": @"Nickname",
                @"value": @"Tom",
                @"valueType": @"string",
            },
            @{
                @"section": @"CatInfo",
                @"title": @"Age",
                @"value": @8,
                @"valueType": @"number",
            },
        ]
    }];

    [subviews addObject:@{
        @"title": @"SomeConfig",
        // Optional. Reserved for the DanceUI team; ignore otherwise.
        // Optional. Reserved fields for the DanceUI project team, please ignore if you are not part of the team.
        @"lookin_source": [self createDanceUIJson],
        // Optional. Recursively add virtual subviews.
        // Optional. You can recursively add your virtual subview.
        @"subviews": @[
            @{ @"title": @"CatConfig0" },
            @{ @"title": @"CatConfig1" }
        ]
    }];
    
    return [subviews copy];
}

- (NSString *)createDanceUIJson {
    NSDictionary *dict = @{
        @"type": @"DanceUIApp.ContentView",
        @"method": @"body.get",
        @"build_path": @"/Users/bytedance/Library/Developer/Xcode/DerivedData/DanceUIApp-ayaxbucdgzeouqefaavnvvhsjpvj/Build/Products/Debug-iphonesimulator/DanceUIApp.app/DanceUIApp"
    };
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dict options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
