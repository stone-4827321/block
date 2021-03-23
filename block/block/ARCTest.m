//
//  ARCTest.m
//  探索本质&捕获变量
//
//  Created by stone on 2021/1/15.
//

#import "ARCTest.h"
#import "STObject.h"

typedef void (^Block)(void);
//查看引用计数
extern uintptr_t _objc_rootRetainCount(id obj);
@implementation ARCTest

+ (Block)returnBlock {
    int a = 1;
    return ^{NSLog(@"%d", a);};
}

int c1 = 1;
+ (void)blockType {
    NSLog(@"ARC!!!");
    
    int a = 1;
    static int b = 1;
    int var = 1;
    int *d = &var;
    STObject *o = [[STObject alloc] init];
    o.age = 1;
    
    Block block1 = ^ (void) {
        NSLog(@"hello");
    };
    NSLog(@"未访问变量 %@", [block1 class]);
    
    //局部变量
    Block block2 = ^ (void) {
        NSLog(@"%d", a);
    };
    NSLog(@"局部变量 %@", [block2 class]);
    
    // 静态变量
    Block block3 = ^ (void) {
        NSLog(@"%d", b);
    };
    NSLog(@"静态变量 %@", [block3 class]);
    
    // 全局变量
    Block block4 = ^ (void) {
        NSLog(@"%d", c1);
    };
    NSLog(@"全局变量 %@", [block4 class]);
    
    // 指针变量
    Block block5 = ^ (void) {
        NSLog(@"%d", *d);
    };
    NSLog(@"指针变量 %@", [block5 class]);
    
    // 对象变量
    Block block6 = ^(void) {
        NSLog(@"%d", o.age);
    };
    NSLog(@"对象变量 %@", [block6 class]);

    NSLog(@"copy %@", [[block6 copy] class]);
    NSLog(@"no reference %@",[^{NSLog(@"%d", a);} class]);
    NSLog(@"return %@", [[self returnBlock] class]);
}




+ (void)address {
    NSLog(@"ARC!!!");

    {
        NSLog(@"堆block捕获普通变量～～～");
        int a = 1;
        NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff34c
        void (^block)(void) = ^(void) {
            NSLog(@"捕获 %p", &a); //堆地址 0x103820010
        };
        block();
        NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff34c
        NSLog(@"%@", block); //堆block
    }
    {
        NSLog(@"栈block捕获普通变量～～～");
        int a = 1;
        NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff314
        ^(void) {
            NSLog(@"捕获 %p", &a); //栈地址 0x7ffeefbff310
        }();
        NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff314
    }
    {
        NSLog(@"堆block捕获__block普通变量～～～");
        __block int a = 1;
        NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff2e8
        void (^block)(void) = ^(void) {
            NSLog(@"捕获 %p", &a); //堆地址 0x103820138
        };
        block();
        NSLog(@"捕获后 %p", &a); //堆地址 0x103820138
        NSLog(@"%@", block); //堆block
    }
    {
        NSLog(@"栈block捕获__block普通变量～～～");
        __block int a = 1;
        NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff288
        ^(void) {
            NSLog(@"捕获 %p", &a); //栈地址 0x7ffeefbff288
        }();
        NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff288
    }
//    {
//        NSLog(@"堆block捕获对象变量～～～");
//        STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x100617830
//        void (^block)(void) = ^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100617830
//        } ;
//        block();
//        NSLog(@"捕获后 %@", a); //堆地址 0x100617830
//        NSLog(@"%@", block); //堆block
//    }
//    {
//        NSLog(@"栈block捕获对象变量～～～");
//        STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x10381ff90
//        ^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x10381ff90
//        }();
//        NSLog(@"捕获后 %@", a); //堆地址 0x10381ff90
//    }
//    {
//        NSLog(@"堆block捕获__block对象变量～～～");
//        __block STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x100617830
//        void (^block)(void) = ^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100617830
//        };
//        block();
//        NSLog(@"捕获后 %@", a); //堆地址 0x100617830
//        NSLog(@"%@", block); //堆block
//    }
//    {
//        NSLog(@"栈block捕获__block对象变量～～～");
//        __block STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x100707bf0
//        ^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100707bf0
//        }();
//        NSLog(@"捕获后 %@", a); //堆地址 0x100707bf0
//    }
}

+ (void)memoryManagement {
    NSLog(@"ARC!!!");

    NSLog(@"堆block捕获对象变量～～～");
    static Block block1;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 11;
        NSLog(@"捕获前 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block1 = ^{
            NSLog(@"捕获 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        };
        NSLog(@"捕获后 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block1();
    }
    NSLog(@"block1 %@", block1);
    block1 = nil;


    NSLog(@"堆block捕获__weak对象变量～～～");
    static Block block2;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 22;
        __weak typeof(o)weako = o;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(weako));
        block2 = ^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(weako));
        };
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(weako));
        block2();
    }
    NSLog(@"block2 %@", block2);

    NSLog(@"堆block捕获__unsafe_unretained对象变量～～～");
    static Block block3;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 33;
        __unsafe_unretained typeof(o)unretainedo = o;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(unretainedo));
        block3 = ^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(unretainedo));
        };
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(unretainedo));
        block3();
    }
    NSLog(@"block3 %@", block3);

    __weak Block block4;
    NSLog(@"栈block捕获对象变量～～～");
    {
        STObject *o = [[STObject alloc] init];
        o.age = 44;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(o));
        block4 = ^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(o));
        };
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(o));
        block4();
    }
    NSLog(@"block4 %@", block4);
    //block4 = nil;

    NSLog(@"堆block捕获__block对象变量～～～");
    static Block block5;
    {
        __block STObject *o = [[STObject alloc] init];
        o.age = 55;
        NSLog(@"捕获前 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block5 = ^{
            NSLog(@"捕获 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        };
        NSLog(@"捕获后 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block5();
    }
    NSLog(@"block5 %@", block5);

    NSLog(@"堆block捕获__block__weak对象变量～～～");
    static Block block6;
    {
        __block __weak STObject *o = [[STObject alloc] init];
        o.age = 66;
        //NSLog(@"捕获前 %lu", _objc_rootRetainCount(weako));
        block6 = ^{
            NSLog(@"%@", o);
            //NSLog(@"捕获 %lu", _objc_rootRetainCount(weako));
        };
        //NSLog(@"捕获后 %lu", _objc_rootRetainCount(weako));
        block6();
    }
    NSLog(@"block6 %@", block6);
    
    NSLog(@"done");
}

@end
