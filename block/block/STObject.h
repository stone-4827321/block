//
//  STObject.h
//  探索本质&捕获变量
//
//  Created by stone on 2021/1/15.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^STBlock)(void);


@interface STObject : NSObject

@property (nonatomic, copy) STBlock block;

@property (nonatomic) int age;

@property (nonatomic, copy) void (^myblock)(STObject *);
@property (nonatomic, copy) void (^myblock2)(void);
//@property (nonatomic, copy) dispatch_block_t myblock2;

- (void)func:(void (^)(void))block;

@end

NS_ASSUME_NONNULL_END
