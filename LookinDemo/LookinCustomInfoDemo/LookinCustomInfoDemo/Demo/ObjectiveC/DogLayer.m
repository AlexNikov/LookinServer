//
//  DogLayer.m
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

#import "DogLayer.h"

@implementation DogLayer

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
        // Shown in Lookin's right-hand attribute panel.
        // These details will be displayed in the right-hand property panel of Lookin.
        @"properties": [self dogLayer_makeCustomProperties],
    };
    return ret;
}

- (NSArray *)dogLayer_makeCustomProperties {
    NSMutableArray *properties = [NSMutableArray array];
    
    // string property
    [properties addObject:@{
        // Optional. Property group title shown in Lookin.
        // Optional. The name of the property group displayed in Lookin.
        @"section": @"DogInfo",
        // Required. Property title shown in Lookin.
        // Required. The name of the property displayed in Lookin.
        @"title": @"Nickname",
        // Optional. Property value shown in Lookin. Omit when nil to avoid NSDictionary crashes.
        // Optional. The value of the property displayed in Lookin. If the property value is nil, do not set this item, otherwise NSDictionary may crash due to inserting nil.
        @"value": @"Sushi",
        // Required. Tells Lookin to parse and display the property as a String.
        // Required. Specify the format in which Lookin should parse and display the property.
        @"valueType": @"string",
        // Optional. When set, the property can be edited live in Lookin.
        //[Warning] Lookin retains this block — watch memory management.
        // Optional. If this field is configured, users can modify the property by Lookin.
        // [Warning] This block will be retained by Lookin indefinitely, so please be extremely careful with memory management.
        @"retainedSetter": ^(NSString *newString) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // number property
    [properties addObject:@{
        @"section": @"DogInfo",
        @"title": @"Age",
        @"value": [NSNumber numberWithDouble:8],
        @"valueType": @"number",
        @"retainedSetter": ^(NSNumber *newNumber) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // bool property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"IsFriendly",
        @"value": [NSNumber numberWithBool:YES],
        @"valueType": @"bool",
        @"retainedSetter": ^(BOOL newBool) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // color property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"SkinColor",
        @"value": [UIColor blueColor],
        @"valueType": @"color",
        @"retainedSetter": ^(UIColor *newColor) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // rect property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogRect",
        @"value": [NSValue valueWithCGRect:CGRectMake(1, 2, 3, 4)],
        @"valueType": @"rect",
        @"retainedSetter": ^(CGRect newRect) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // size property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogSize",
        @"value": [NSValue valueWithCGSize:CGSizeMake(5, 6)],
        @"valueType": @"size",
        @"retainedSetter": ^(CGSize newSize) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // point property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogPoint",
        @"value": [NSValue valueWithCGPoint:CGPointMake(7, 8)],
        @"valueType": @"point",
        @"retainedSetter": ^(CGPoint newPoint) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // insets property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogInsets",
        @"value": [NSValue valueWithUIEdgeInsets:UIEdgeInsetsMake(1, 2, 3, 4)],
        @"valueType": @"insets",
        @"retainedSetter": ^(UIEdgeInsets newInsets) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // shadow property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogShadow",
        @"value": @{
            @"opacity": @0.5,
            @"offset": [NSValue valueWithCGSize:CGSizeMake(5, 10)],
            @"radius": @2.5,
            // Optional; omit when the color is nil
            // Optional. Do not set this item when the shadow color is nil.
            @"color": UIColor.redColor
        },
        @"valueType": @"shadow"
    }];
    
    // enum property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"Type",
        @"value": @"Corgi",
        @"valueType": @"enum",
        // Required for enum valueType: all allowed enum values.
        // When valueType is "enum", this item must be set, with the content being all available enum cases.
        @"allEnumCases": @[@"Corgi", @"Samoyed", @"Golden Retriever", @"Teddy"],
        @"retainedSetter": ^(NSString *newValue) {
            NSLog(@"Try to modify by Lookin.");
        }
    }];
    
    // json property
    [properties addObject:@{
        @"section": @"Animal Info",
        @"title": @"DogJson",
        @"value": [self createSomeJson],
        @"valueType": @"json"
    }];
    
    return [properties copy];;
}

/*
 JSON may only use "title", "desc", and "details" keys.
 "title" and "desc" must be strings; "details" must be an array.
 */
- (NSString *)createSomeJson {
    NSArray *arr = @[
        @{
            @"title":  @"allowedBehaviors",
            @"desc": @"HostingControllerAllowedBehaviors",
            @"details": @[
                @{
                    @"title":  @"rawValue",
                    @"desc": @"0"
                }, @{
                    @"title":  @"contentScrollViewBridge",
                    @"desc": @"UIKitContentScrollViewBridge",
                    @"details": @[
                        @{
                            @"title":  @"bridgeSetEdges",
                            @"desc": @"[:]"
                        }, @{
                            @"title":  @"pixelLength",
                            @"desc": @"0.33333333"
                        }]
                }]
        },
        @{
            @"title":  @"scenePhase",
            @"desc": @"active"
        }
    ];
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:arr options:0 error:&error];
    NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    return jsonString;
}

@end
