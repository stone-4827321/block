//
//  main.m
//  block_hook
//
//  Created by stone on 2021/1/28.
//

#import <Foundation/Foundation.h>
#import "WBHookBlock.h"

typedef void(^testBlock_04)(void);

typedef void(^testBlock)(int a);

typedef void(^testBlock_02)(int b);

typedef void(^testBlock_03)(int b);


NSMethodSignature* methodSignatureForBlockSignature(NSMethodSignature *original) {
    if (!original) return nil;

    if (original.numberOfArguments < 1) {
        return nil;
    }

    if (original.numberOfArguments >= 2 && strcmp(@encode(SEL), [original getArgumentTypeAtIndex:1]) == 0) {
        return original;
    }

    // initial capacity is num. arguments - 1 (@? -> @) + 1 (:) + 1 (ret type)
    // optimistically assuming most signature components are char[1]
    NSMutableString *signature = [[NSMutableString alloc] initWithCapacity:original.numberOfArguments + 1];

    const char *retTypeStr = original.methodReturnType;
    [signature appendFormat:@"%s%s%s", retTypeStr, @encode(id), @encode(SEL)];

    for (NSUInteger i = 1; i < original.numberOfArguments; i++) {
        const char *typeStr = [original getArgumentTypeAtIndex:i];
        NSString *type = [[NSString alloc] initWithBytesNoCopy:(void *)typeStr length:strlen(typeStr) encoding:NSUTF8StringEncoding freeWhenDone:NO];
        [signature appendString:type];
    }

    return [NSMethodSignature signatureWithObjCTypes:signature.UTF8String];
}

enum {
  BLOCK_DEALLOCATING =      (0x0001),  // runtime
  BLOCK_REFCOUNT_MASK =     (0xfffe),  // runtime
  BLOCK_NEEDS_FREE =        (1 << 24), // runtime
  BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
  BLOCK_HAS_CTOR =          (1 << 26), // compiler: helpers have C++ code
  BLOCK_IS_GC =             (1 << 27), // runtime
  BLOCK_IS_GLOBAL =         (1 << 28), // compiler
  BLOCK_USE_STRET =         (1 << 29), // compiler: undefined if !BLOCK_HAS_SIGNATURE
  BLOCK_HAS_SIGNATURE  =    (1 << 30)  // compiler
};

/* Revised new layout. */
//struct Block_descriptor {
//    unsigned long int reserved;
//    unsigned long int size;
//    void (*copy)(void *dst, void *src);
//    void (*dispose)(void *);
//    const char *signature;
//    const char *layout;
//};
//
//struct Block_layout {
//    void *isa;
//    int flags;
//    int reserved;
//    void (*invoke)(void *, ...);
//    struct Block_descriptor *descriptor;
//    /* Imported variables. */
//};

struct Block_descriptor_1 {
    uintptr_t reserved;
    uintptr_t size;
};

struct Block_descriptor_2 {
    // requires BLOCK_HAS_COPY_DISPOSE
    void (*copy)(void *dst, const void *src);
    void (*dispose)(const void *);
};

struct Block_descriptor_3 {
    // requires BLOCK_HAS_SIGNATURE
    const char *signature;  // 签名
    const char *layout;     // contents depend on BLOCK_HAS_EXTENDED_LAYOUT
};

struct Block_layout {
    void *isa;
    int flags; // block属性的标识符
    int reserved;
    void (*invoke)(void *, ...); // 块代码的函数指针
    struct Block_descriptor1 *descriptor;
};


void testHook() {
    NSObject *obj = [[NSObject alloc] init];
    int c = 100;
    testBlock block1 = ^(int a) {
        NSLog(@"block1 a is %d",a);
        NSLog(@"block1 c is %d",c);
        NSLog(@"obj is %@",obj);
    };
    
    testBlock block2 = ^(int a) {
        NSLog(@"block2 a is %d",a);
        NSLog(@"block2 c is %d",c);

    };
    NSLog(@"block1 = %@", block1);
    NSLog(@"block2 = %@", block2);

    
    [WBHookBlock hookBlock:block1 alter:block2 position:WBHookBlockPositionBefore];
    
    block1(20);
}

int main(int argc, const char * argv[]) {
    @autoreleasepool {
        //callBlockByFuncPointer();
        
        int (^originalBlock)(int, int ) = ^int(int a, int b) {
            NSLog(@"Block called %d %d", a, b);
            return a + b;
        };
        
        struct Block_layout *block = (struct Block_layout *)(__bridge void *)originalBlock;
        
        int (*blockIMP)(void *, int, int) = (int (*)(void *, int, int))(block->invoke);
        int result = blockIMP(block, 1, 2);
        NSLog(@"直接执行block %d", result);
        
        // 没有签名，直接返回空
        if (!(block->flags & BLOCK_HAS_SIGNATURE)) {
            return 0;
        }

        void *desc = block->descriptor;
        // reserved和size变量
        desc += 2 * sizeof(unsigned long int);
        // copy和dispose变量
        if (block->flags & BLOCK_HAS_COPY_DISPOSE) {
            desc += 2 * sizeof(void *);
        }
        const char *descChar = (*(const char **)desc);
        NSMethodSignature *signature = [NSMethodSignature signatureWithObjCTypes:descChar];
        
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
        int a = 3;
        int b = 4;
        int c;
        [invocation setArgument:&a atIndex:1];
        [invocation setArgument:&b atIndex:2];
        [invocation invokeWithTarget:originalBlock];
        [invocation getReturnValue:&c];
        NSLog(@"NSInvocation执行block %d", c);
    }
    return 0;
}
