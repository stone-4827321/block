//
//  main.m
//  探索本质&捕获变量
//
//  Created by stone on 2021/1/14.
//

#import <Foundation/Foundation.h>
#import "ARCTest.h"
#import "MRCTest.h"
#import "STObject.h"

extern uintptr_t _objc_rootRetainCount(id obj);

typedef void (^Block)(void);

enum {
    BLOCK_FIELD_IS_OBJECT   =  3,  // id, NSObject, __attribute__((NSObject)), block, ...  ///Junes OC 对象类型，如前边这几种
    BLOCK_FIELD_IS_BLOCK    =  7,  ///Junes 一个 Block 变量
    BLOCK_FIELD_IS_BYREF    =  8,  ///Junes 栈区中被 __block 修饰变量后产生的结构体
    BLOCK_FIELD_IS_WEAK     = 16,  ///Junes __weak 修饰的变量，只在 Block_byref 管理内部对象时使用，即 __block __weak id;
    BLOCK_BYREF_CALLER      = 128, ///Junes 在处理 Block_byref 内部对象内存时加上的额外标记，配合上边的几个枚举值一起使用
};
//
//BLOCK_ALL_COPY_DISPOSE_FLAGS =
//    BLOCK_FIELD_IS_OBJECT | BLOCK_FIELD_IS_BLOCK | BLOCK_FIELD_IS_BYREF |
//BLOCK_FIELD_IS_WEAK | BLOCK_BYREF_CALLER;

#pragma mark - 探索本质
// 探寻本质
void stone() {
    void (^block)(void) = ^ (void) {
        NSLog(@"hello stone");
    };
    block();
}

#pragma mark - 捕获变量

// 局部变量
void member_variable() {
    int a = 1;
    void (^block)(void) = ^ (void) {
        NSLog(@"局部变量 %d", a);
    };
    a = 2;
    block();
}

// 静态变量
void static_variable() {
    static int b = 1;
    //NSLog(@"!!!!!!%p", &b);
    void (^block)(void) = ^ (void) {
        NSLog(@"静态变量 %d", b);
    };
    b = 2;
    block();
}

// 全局变量
int c = 1;
void global_variable() {
    void (^block)(void) = ^ (void) {
        NSLog(@"全局变量 %d", c);
    };
    c = 2;
    block();
}

// 指针变量
void pointer_variable() {
    int var = 1;
    int *d = &var;
    //NSLog(@"!!!!!!%p", d);
    void (^block)(void) = ^ (void) {
        NSLog(@"指针变量 %d", *d);
    };
    var = 2;
    block();
}

// 对象变量
void class_variable() {
    STObject *o = [[STObject alloc] init];
    o.age = 1;
    void (^block)(void) = ^ (void) {
        NSLog(@"对象变量 %d", o.age);
    };
    o.age = 2;
    block();
}

// weak对象变量
void class_variable_weak() {
//    __weak STObject *o = [[STObject alloc] init];
//    o.age = 1;
//    //__weak typeof(o)weakO = o;
//    void (^block)(void) = ^ (void) {
//        NSLog(@"weak变量 %d", o.age);
//    };
//    o.age = 2;
//    block();
}


void block_variable() {
    __block int a = 1;
    void (^block)(void) = ^ (void) {
        a = 2;
    };
    block();
    NSLog(@"block %d", a);
}

void block_class_variable() {
    __block STObject *o = [[STObject alloc] init];
    void (^block)(void) = ^ (void) {
        NSLog(@"%p", o);
        //o = [[STObject alloc] init];
    };
    //[o release];
    block();
    NSLog(@"%@", block);
}

// 循环引用
void circular_reference () {
    {
        STObject *o = [[STObject alloc] init];
        o.age = 1;
        NSLog(@"%@ %d", o, o.age);
        void (^block)(STObject *) = ^(STObject *obj) {
            NSLog(@"%@ %d", obj, obj.age);
            obj.age = 11;
        };
        block(o);
        NSLog(@"%@ %d", o, o.age);
    }
    {
        STObject *o = [[STObject alloc] init];
        o.age = 2;
        NSLog(@"%@ %d", o, o.age);
        o.myblock = ^(STObject *obj) {
            NSLog(@"%@ %d", obj, obj.age);
            NSLog(@"%@ %d", o, o.age);
            obj.age = 22;
        };
        o.myblock(o);
        NSLog(@"%@ %d", o, o.age);
    }
    {
        STObject *o = [[STObject alloc] init];
        o.age = 3;
        NSLog(@"%@ %d", o, o.age);
        o.myblock = ^(STObject *obj) {
            NSLog(@"%@ %d", obj, obj.age);
            obj.age = 33;
        };
        o.myblock(o);
        NSLog(@"%@ %d", o, o.age);
    }
    
    {
        STObject *o = [[STObject alloc] init];
        o.age = 4;
        void (^block)(void) = ^(void) {
            NSLog(@"%@ %d", o, o.age);
            o.age = 44;
        };
        [o func:block];
        NSLog(@"%@", block);

    }
}


#pragma mark -





int main(int argc, const char * argv[]) {
    @autoreleasepool {

//        NSLog(@"捕获变量");
//        member_variable();
//        static_variable();
//        global_variable();
//        pointer_variable();
//        class_variable();
//        class_variable_weak();
//        NSLog(@"～～～～～～～～～～～");

        
        
//        NSLog(@"内存类型");
//        [ARCTest blockType];
//        [MRCTest blockType];
//        NSLog(@"～～～～～～～～～～～");

        
        
//        NSLog(@"地址");
//        [ARCTest address];
//        [MRCTest address];
//        NSLog(@"～～～～～～～～～～～");

        
        
//        NSLog(@"__block");
//        block_variable();
//        block_class_variable();
//        NSLog(@"～～～～～～～～～～～");
        
//        NSLog(@"内存管理");
//        [ARCTest memoryManagement];
//        [MRCTest memoryManagement];
//        NSLog(@"～～～～～～～～～～～");

//        NSLog(@"循环引用");
//        circular_reference();
    }
    return 0;
}


