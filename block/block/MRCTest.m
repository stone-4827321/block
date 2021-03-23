//
//  MRCTest.m
//  探索本质&捕获变量
//
//  Created by stone on 2021/1/15.
//

#import "MRCTest.h"
#import "STObject.h"

typedef void (^Block)(void);
//查看引用计数
extern uintptr_t _objc_rootRetainCount(id obj);
@interface MRCTest ()

@end
@implementation MRCTest

+ (Block)returnBlock {
    int a = 1;
    return [^{NSLog(@"%d", a);} copy];
}

int c2 = 1;
+ (void)blockType {
    NSLog(@"MRC!!!");

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
        NSLog(@"%d", c2);
    };
    NSLog(@"全局变量 %@", [block4 class]);
    
    // 指针变量
    Block block5= ^ (void) {
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
    NSLog(@"MRC!!!");

    {
        NSLog(@"堆block捕获普通变量～～～");
        int a = 1;
        NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff34c
        void (^block)(void) = [^(void) {
            NSLog(@"捕获 %p", &a); //堆地址 0x103820370
        } copy];
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
        void (^block)(void) = [^(void) {
            NSLog(@"捕获 %p", &a); //堆地址 0x100508d88
        } copy];
        block();
        NSLog(@"捕获后 %p", &a); //堆地址 0x100508d88
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
//        NSLog(@"捕获前 %@", a); //堆地址 0x100509620
//        void (^block)(void) = [^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100509620
//        } copy];
//        block();
//        NSLog(@"捕获后 %@", a); //堆地址 0x100509620
//        NSLog(@"%@", block); //堆block
//    }
//    {
//        NSLog(@"栈block捕获对象变量～～～");
//        STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x100509650
//        ^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100509650
//        }();
//        NSLog(@"捕获后 %@", a); //栈地址 0x100509650
//    }
//    {
//        NSLog(@"堆block捕获__block对象变量～～～");
//        __block STObject *a = [[STObject alloc] init];
//        NSLog(@"捕获前 %@", a); //堆地址 0x100794ab0
//        void (^block)(void) = [^(void) {
//            NSLog(@"捕获 %@", a); //堆地址 0x100794ab0
//        } copy];
//        block();
//        NSLog(@"捕获后 %@", a); //堆地址 0x100794ab0
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
    NSLog(@"MRC!!!");
        
    NSLog(@"堆block捕获对象变量～～～");
    static Block block1;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 111;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(o));
        block1 = [^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(o));
        } copy];
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(o));
        block1();
        [o release];
    }
    NSLog(@"block1 %@", block1);

    
    NSLog(@"堆block捕获__weak对象变量～～～");
    static Block block2;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 222;
        __weak STObject *weako = o;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(weako));
        block2 = [^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(weako));
        } copy];
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(weako));
        block2();
        [o release];
    }
    NSLog(@"block2 %@", block2);

    NSLog(@"堆block捕获__unsafe_unretained对象变量～～～");
    static Block block3;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 333;
        __unsafe_unretained STObject *unretainedo = o;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(unretainedo));
        block3 = [^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(unretainedo));
        } copy];
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(unretainedo));
        block3();
        [o release];
    }
    NSLog(@"block3 %@", block3);
    
    NSLog(@"栈block捕获对象变量～～～");
    static Block block4;
    {
        STObject *o = [[STObject alloc] init];
        o.age = 444;
        NSLog(@"捕获前 %lu", _objc_rootRetainCount(o));
        block4 = ^{
            NSLog(@"捕获 %lu", _objc_rootRetainCount(o));
        };
        NSLog(@"捕获后 %lu", _objc_rootRetainCount(o));
        block4();
        [o release];
    }
    NSLog(@"block4 %@", block4);
    
    NSLog(@"堆block捕获__block对象变量～～～");
    static Block block5;
    {
        __block STObject *o = [[STObject alloc] init];
        o.age = 555;
        NSLog(@"捕获前 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block5 = [^{
            NSLog(@"捕获 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        } copy];
        NSLog(@"捕获后 %@ %lu %p", o, _objc_rootRetainCount(o), &o);
        block5();
        [o release];
    }
    NSLog(@"block5 %@", block5);
    
    NSLog(@"done");
}

@end
