//
//  STObject.m
//  探索本质&捕获变量
//
//  Created by stone on 2021/1/15.
//

#import "STObject.h"


@implementation STObject

- (void)dealloc {
    NSLog(@"stone dealloc %d", _age);
    //[super dealloc];
}

- (id)copyWithZone:(nullable NSZone *)zone {
    STObject *obj = [[STObject alloc] init];
    return obj;
}

- (id)mutableCopyWithZone:(nullable NSZone *)zone {
    STObject *obj = [[STObject alloc] init];
    return obj;
}

- (void)func:(void (^ NS_NOESCAPE)(void))block {
    if (block) {
        self.myblock2 = block;
        block();
    }
}

@end
