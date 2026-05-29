//
//  SomeViewModel.m
//  LookinCustomInfoDemo
//
//  Maintained by Cursor Agent.
//

#import "SomeViewModel.h"

@implementation SomeViewModel

- (instancetype)init
{
    self = [super init];
    if (self) {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"Lookin_RelationSearch" object:self];
    }
    return self;
}

@end
