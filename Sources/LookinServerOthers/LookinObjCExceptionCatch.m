#import <Foundation/Foundation.h>
#import <objc/runtime.h>

void LookinCatchObjCException(void (NS_NOESCAPE ^ _Nullable tryBlock)(void),
                              NSException * _Nullable * _Nullable exceptionOut) {
    @try {
        if (tryBlock) {
            tryBlock();
        }
        if (exceptionOut) {
            *exceptionOut = nil;
        }
    } @catch (NSException *exception) {
        if (exceptionOut) {
            *exceptionOut = exception;
        }
    }
}

const char *LookinObjectGetIvarSELName(id object, Ivar ivar) {
    SEL action = ((SEL (*)(id, Ivar))object_getIvar)(object, ivar);
    if (action == NULL) {
        return NULL;
    }
    return sel_getName(action);
}
