//
//  NSMutableURLRequest+FixCopy.m
//  Kakapo
//
//  Created by Alex Manzella on 12/07/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

#import "NSMutableURLRequest+FixCopy.h"
#import <objc/runtime.h>

static NSString * RequestHTTPBodyKey = @"kkp_requestHTTPBody";

@implementation NSMutableURLRequest (FixCopy)

#pragma mark - Method Swizzling

/**
 We swizzle NSURLRequest to be able to use the HTTPBody when handling NSURLSession. If a custom NSURLProtocol is provided to NSURLSession,
 even if the NSURLRequest has an HTTPBody non-nil when the request is passed to the NRURLProtocol (such as canInitWithRequest: or
 canonicalRequestForRequest:) has an empty body.
 
 **[See radar](http://openradar.appspot.com/15993891)**
 **[See issue #9](https://github.com/devlucky/Kakapo/issues/9)**
 **[See relevant issue](https://github.com/AliSoftware/OHHTTPStubs/issues/52)**
 */
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        SEL originalSelector = @selector(setHTTPBody:);
        SEL swizzledSelector = @selector(kkp_setHTTPBody:);
        Method originalMethod = class_getInstanceMethod(self, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(self, swizzledSelector);
        method_exchangeImplementations(originalMethod, swizzledMethod);
    });
}

- (void)kkp_setHTTPBody:(nullable NSData *)body {
    if (body != nil) {
        [NSURLProtocol setProperty:body forKey:RequestHTTPBodyKey inRequest:self];
    }
    [self kkp_setHTTPBody:body];
}

@end
