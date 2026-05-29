//
//  UIView+Custom.m
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

#import "UIView+Custom.h"

@implementation UIView (Custom)

/// Implement this method to expose custom properties in Lookin
/// Check whether a parent, child, or category already implements this method. To avoid conflicts, rename it to lookin_customDebugInfos_0 (the trailing 0 may be 0–5).
/// Lookin calls this on every refresh; keep it fast to avoid slowing down inspection.
///
/// Implement this method to display custom properties in Lookin.
/// Please note if this method has already been implemented by the superclass, subclass, or category. If so, to avoid conflicts, you can rename this method to lookin_customDebugInfos_0 (the trailing number 0 can be replaced with any number from 0 to 5).
/// This method is called every time Lookin refreshes, so if this method takes a long time to execute, it will slow down the refresh speed.
///
/// https://bytedance.feishu.cn/docx/TRridRXeUoErMTxs94bcnGchnlb
- (NSDictionary<NSString *, id> *)lookin_customDebugInfos_0 {
    NSDictionary<NSString *, id> *ret = @{
        @"properties": [self category_makeCustomProperties],
    };
    return ret;
}

- (NSArray *)category_makeCustomProperties {
    NSMutableArray *properties = [NSMutableArray array];
    
    [properties addObject:@{
        @"section": @"Appearance",
        @"title": @"Brightness",
        @"value": @8.8,
        @"valueType": @"number"
    }];
    
    return [properties copy];;
}

@end
