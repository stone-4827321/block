# 定义和使用

- block 是封装了函数以及函数调用环境的 OC 对象。

- block 的声明和定义格式如下：

  ```objective-c
  // 返回值 (^名称)(参数)
  int (^block)(int arg1, int arg2);
  block = ^int (int arg1, int arg2) {    
  	//do something;
    return 0;
  };
  ```

- block 的使用：

  - 作为成员变量

  ```objective-c
  @property (nonatomic, copy) int (^block)(int arg1, int arg2);
  ```

  - 作为函数的参数

  ```objective-c
  - (void)func:(int (^)(int, int))block {   
  }
  ```

  - 作为函数的返回

  ```objective-c
  - (int (^)(int arg1, int arg2))func {
  }
  ```

  - 使用 `typedef` 进行简写：

  ```objective-c
  typedef int (^Block)(int arg1, int arg2);
  
  @property (nonatomic, copy) Block block;
  
  - (Block)func {
  }
  
  - (void)func:(Block)block {
  }
  ```

- `dispatch_block_t` 用于快速创建不带参数和返回值的 block。

  ```objective-c
  @property (nonatomic, copy) dispatch_block_t block;
  定义
  typedef void (^dispatch_block_t)(void);
  等于
  typedef void (^Block)(void);
  @property (nonatomic, copy) Block block;
  ```

# 探寻本质

- ```objective-c
  void (^block)(void) = ^ (void) {
      NSLog(@"hello stone");
  };
  block();
  ```

- 使用 **xcrun** 命令将以下 .m 文件转换为 .cpp 文件。

  - 编译成 MRC 代码：`xcrun -sdk iphoneos clang -arch arm64 -rewrite-objc main.m -o main.cpp`
  - 编译成 ARC 代码：如果代码中含有 `__weak` 关键字时，需要告知编译器使用 ARC 环境及版本号否则会报错，添加参数 ` -fobjc-arc -fobjc-runtime=ios-8.0.0`

  ```c++
  //****定义 block****
  void (*block)(void) = ((void (*)())&__xxx_block_impl_0((void *)__xxx_block_func_0, &__stone_block_desc_0_DATA));
  //****调用 block****
  ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
  
  
  // __stone_block_func_0 封装了block块中的代码
  static void __xxx_block_func_0(struct __stone_block_impl_0 *__cself) {
      NSLog(@"hello stone");
  }
  ```

- 定义 block：

  - 将函数 `__xxx_block_impl_0` 的地址赋值给了 block —— 该函数实际上是构造体的构造函数—— 将一个 `__xxx_block_impl_0` 结构体的地址赋值给了 block。
  - block 结构体有两个成员变量 `struct __block_impl impl` 和 `struct __xxx_block_desc_0* Desc`。前者保存了块方法指针 `FuncPtr`，后者保存了内存大小等描述信息。

  ```c++
  struct __xxx_block_impl_0 {
    struct __block_impl impl;
    struct __xxx_block_desc_0* Desc;
    __xxx_block_impl_0(void *fp, struct __xxx_block_desc_0 *desc, int flags=0) {
      impl.isa = &_NSConcreteStackBlock;
      impl.Flags = flags;
      impl.FuncPtr = fp;
      Desc = desc;
    }
  };
  
  // impl的类型
  struct __block_impl {
    void *isa;
    int Flags;
    int Reserved;
    void *FuncPtr;
  };
  
  // Desc的类型，并初始化__xxx_block_desc_0_DATA
  static struct __xxx_block_desc_0 {
    size_t reserved;
    size_t Block_size;
  } __xxx_block_desc_0_DATA = { 0, sizeof(struct __xxx_block_impl_0)};
  ```

- 简而言之：**block 的本质就是一个结构体，内部含有 `isa` 指针，块方法指针和其他描述信息 —— block 就是一个 OC对象**。

# 捕获变量

- 在 block 内部，创建一个变量来存放外部变量，这就叫做**捕获**。

## 基本数据类型的捕获

- **局部变量：定义后持有普通变量，调用时使用值传递方式**

  ```objective-c
  void member_variable() {
      int a = 1;
      void (^block)(void) = ^ (void) {
          NSLog(@"%d", a);
      };
      a = 2;
      block();
  }
  // 输出 1
  ```
  - block 结构体中多了一个成员变量。

  ```c++
  struct __member_variable_block_impl_0 {
    struct __block_impl impl;
    struct __member_variable_block_desc_0* Desc;
    // 普通变量
    int a;
    // 构造函数
    __member_variable_block_impl_0(void *fp, struct __member_variable_block_desc_0 *desc, int _a, int flags=0) : a(_a) {
      impl.isa = &_NSConcreteStackBlock;
      impl.Flags = flags;
      impl.FuncPtr = fp;
      Desc = desc;
    }
  };
  ```

  - block 的构造函数调用时，需要多传递一个参数。

  ```c++
  void member_variable() {
      int a = 1;
      // 使用值传递方式将a传入构造方法
      void (*block)(void) = ((void (*)())&__member_variable_block_impl_0((void *)__member_variable_block_func_0, &__member_variable_block_desc_0_DATA, a));
      a = 2;
      ((void (*)(__block_impl *))((__block_impl *)block)->FuncPtr)((__block_impl *)block);
  }
  ```

  - block 代码块调用时，使用从自身结构体中取出的成员变量。

  ```c++
  static void __member_variable_block_func_0(struct __member_variable_block_impl_0 *__cself) {
    // 使用时直接取值
    int a = __cself->a; // bound by copy
  
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_dg3ds_t12n936ylr_k8vpvw80000gn_T_main_cce6ac_mi_1, a);
  }
  ```

- **静态变量：定义后持有指针变量，调用时使用引用传递方式（传入变量地址）**

  ```objective-c
  void static_variable() {
      static int b = 1;
      void (^block)(void) = ^ (void) {
          NSLog(@"%d", b);
      };
      b = 2;
      block();
  }
  
  // 输出 2
  ```

  ```c++
  struct __static_variable_block_impl_0 {
    // 指针变量
    int *b;
    __static_variable_block_impl_0(void *fp, struct __static_variable_block_desc_0 *desc, int *_b, int flags=0) : b(_b) {
    }
  };
  
  void static_variable() {
      static int b = 1;
      // 使用引用传递方式将b传入构造方法，即传入b的地址
      void (*block)(void) = ((void (*)())&__static_variable_block_impl_0((void *)__static_variable_block_func_0, &__static_variable_block_desc_0_DATA, &b));
  }
  
  static void __static_variable_block_func_0(struct __static_variable_block_impl_0 *__cself) {
    // 使用时通过间接寻址取值
    int *b = __cself->b; // bound by copy
  	NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_dg3ds_t12n936ylr_k8vpvw80000gn_T_main_ba7984_mi_2, (*b));
  }
  ```

- **全局变量：定义后不持有，调用时不传递**

  ```objective-c
  int c = 1;
  void global_variable() {
      void (^block)(void) = ^ (void) {
          NSLog(@"%d", c);
      };
      c = 2;
      block();
  }
  // 输出 2
  ```

  ```c++
  struct __global_variable_block_impl_0 {
  	//无额外的变量
  }
  
  void global_variable() {
      // 不需要传递c
      void (*block)(void) = ((void (*)())&__global_variable_block_impl_0((void *)__global_variable_block_func_0, &__global_variable_block_desc_0_DATA));
  }
  
  int c = 1;
  static void __global_variable_block_func_0(struct __global_variable_block_impl_0 *__cself) {
    // 直接使用c，不需要block
    NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_dg3ds_t12n936ylr_k8vpvw80000gn_T_main_5fea04_mi_3, c);
  }
  ```

- **指针变量：定义后持有指针变量，调用时使用指针传递方式**

  ```objective-c
  void reference_variable() {
      int var = 1;
      int *d = &var;
      void (^block)(void) = ^ (void) {
          NSLog(@"指针变量 %d", *d);
      };
      var = 2;
      block();
  }
  // 输出 2
  ```

  ```c++
  struct __reference_variable_block_impl_0 {
  	// 指针变量
    int *d;
    __reference_variable_block_impl_0(void *fp, struct __reference_variable_block_desc_0 *desc, int *_d, int flags=0) : d(_d) {
  };
    
  void reference_variable() {
      int var = 1;
      int *d = &var;
    	// 使用指针传递方式将d传入构造方法
      void (*block)(void) = ((void (*)())&__reference_variable_block_impl_0((void *)__reference_variable_block_func_0, &__reference_variable_block_desc_0_DATA, d));
  }
    
  static void __reference_variable_block_func_0(struct __reference_variable_block_impl_0 *__cself) {
    // 使用时通过指针取值
    int *d = __cself->d; // bound by copy
  	NSLog((NSString *)&__NSConstantStringImpl__var_folders_hz_dg3ds_t12n936ylr_k8vpvw80000gn_T_main_a7c168_mi_4, *d);
  }
  ```

- **为什么不同变量会有这种差异呢？**

  - 局部变量可能会销毁，block 在执行的时候自动变量可能已经被销毁了，此时如果再去访问被销毁的地址就会发生坏内存访问，因此对于自动变量一定是值传递而不可能是指针传递。
  - 静态变量不会被销毁，可以直接传递地址。
  - 全局变量无论在哪里都可以访问，当访问全局变量时，block 都不需要对其捕获。
  - 当访问指针变量或对象变量时，实例对象被捕获到 block 内部，保存的其实也是对象的地址。
  - 因此，**在 block 定义之后对其访问的局部变量进行改变是无法在 block 中体现的，且不能在 block 中对变量的值进行修改，而静态变量，（静态）全局变量，指针变量则相反。**

- 简而言之，**如果 block 捕获了变量，结构体中增加一个成员变量，存储通过值传递，指针传递或引用传递等方式传递的变量的值或地址，并在 block 块方法中使用**。

## 捕获变量的内存位置

- 当 block 在栈上时，捕获的变量也是在栈上。

  - 由于值传递方式，捕获的变量和外部定义变量的栈地址**不一样**。

  ```objective-c
  int a = 1;
  NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff314
  ^(void) {
      NSLog(@"捕获 %p", &a); //栈地址 0x7ffeefbff310
  }();
  NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff314
  ```

  - 使用 `__block` 修饰的局部变量，由于使用了地址传递方式，捕获的变量和外部定义变量的栈地址**一样**。

  ```objective-c
  __block int a = 1;
  NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff288
  ^(void) {
      NSLog(@"捕获 %p", &a); //栈地址 0x7ffeefbff288
  }();
  NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff288
  ```

- 当 block 被复制到堆上时，捕获的变量也被复制到堆上。

  ```objective-c
  int a = 1;
  NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff34c
  void (^block)(void) = ^(void) {
      NSLog(@"捕获 %p", &a); //堆地址 0x103820010
  };
  block();
  NSLog(@"捕获后 %p", &a); //栈地址 0x7ffeefbff34c
  ```

  - 使用 `__block` 修饰的局部变量，由于被转换为结构体且复制到堆上，后续访问的都是堆上的地址。

  ```objective-c
  __block int a = 1;
  NSLog(@"捕获前 %p", &a); //栈地址 0x7ffeefbff34c
  void (^block)(void) = ^(void) {
      NSLog(@"捕获 %p", &a); //堆地址 0x103820010
  };
  block();
  NSLog(@"捕获后 %p", &a); //堆地址 0x103820010
  ```

# 内存类型

- 测试：https://www.zybuluo.com/MicroCai/note/49713

## MRC环境

- 关闭 ARC 回到 MRC 环境下，因为 ARC 下系统会默认进行内存管理，可能会影响最终的结果。

- block 的类型和其是否访问变量，访问变量的类型相关。
  | block类型             | 环境                                     | 存放区域 |
  | --------------------- | ---------------------------------------- | -------- |
  | **__NSGlobalBlock__** | 没有访问任何变量，访问静态变量或全局变量 | 数据段   |
  | **__NSStackBlock__**  | 访问局部变量或指针变量                   | 栈       |
  | **__NSMallocBlock__** | NSStackBlock 调用了 `copy`               | 堆       |

- 保存在栈的 block 会被系统自动回收内存，在 ARC 环境下，以下的代码运行结果不可预料。因为，block 是 `__NSStackBlock__` 类型，函数运行之后栈内存中 block 所占用的内存就被系统回收，再次调用就会出错。

  ```objective-c
  void (^blcok)(void);
  - (void)define__NSStackBlock_ {
    	int a = 0;
      blcok = ^(void) { NSLog(@"%d", a);};
      NSLog(@"%@", [blcok class]);
  }
  
  - (void)use__NSStackBlock_ {
      blcok();
  }
  
  [m define__NSStackBlock_];
  [m use__NSStackBlock_];
  // 输出 __NSStackBlock__
  // 输出 16020
  ```

  解决方案：对 block 进行 `copy` 操作，将其移动到堆上。

  ```objective-c
  blcok = [^(void) { NSLog(@"%d", a);} copy];
  ```

## ARC环境

- 在 ARC 环境下，编译器会根据情况自动将栈上的 block 进行一次 `copy` 操作，将 block 复制到堆上。

- 在什么情况下会对栈上的 block 进行 `copy`  操作？

  - 手动调用 `copy`；
  - block 是函数的返回值；

  ```objective-c
  typedef void (^Block)(void);
  Block block() {
      int a = 1;
      return ^{NSLog(@"%d", a);};
  }
  NSLog(@"%@", [block() class]);
  // 输出 __NSMallocBlock__
  ```

  > MRC 环境下函数返回一个 block 时，系统会强制要求对 block 进行 `copy` 后再返回，否则编译不通过。
  >

  - 当 block 被强引用，被赋值给 `__strong` 或者 `id` 类型；

  ```objective-c
  int a = 1;
  NSLog(@"%@",[^{NSLog(@"%d", a);} class]); 
  // 输出 __NSStackBlock__
  Block block = ^{NSLog(@"%d", a);};
  NSLog(@"%@",[block class]);
  // 输出 __NSMallocBlock__
  ```

  - block作为Cocoa API中方法名含有usingBlock的方法参数；

  - block作为GCD API的方法参数。

- 使用 `copy` 修饰 block 是 MRC 时期的遗留物，这在 MRC 时期是至关重要的事情。在使用 ARC 的现在，`strong` 是可以代替的，为了保持一致，还是推荐使用 `copy` 。


# __block

- 默认情况下 block 不能修改外部的局部变量（因为是值传递方式）：局部变量存在于定义函数的栈空间内部，而 block 块的代码和函数的栈空间不一样，其获取的是 block 结构体存储的变量，并不是定义函数中的局部变量。

  - 引用传递方式的变量可以在 block 中修改，如静态变量。
  - 指针传递方式的变量，不能修改指针指向的地址，但可以修改指针指向的地址上存储的值。

  ```objective-c
  int var = 1;
  int *d = &var;
  void (^block)(void) = ^ (void) {
      *d = 2;
  };
  block();
  NSLog(@"%d", *d);
  // 输出 2
  
  int var = 1;
  int *d = &var;
  int newVar = 2;
  void (^block)(void) = ^ (void) {
      d = &newVar; //报错 Variable is not assignable (missing __block type specifier)
  };
  ```

  > 三种传递方式的区别：<https://www.cnblogs.com/yanlingyin/archive/2011/12/07/2278961.html>

- 使用 `__block` 修饰局部变量后，可以在 block 内部修改该局部变量的值。

  ```objective-c
  __block int age = 1;
  void (^block)(void) = ^{
      age = 2;
  };
  block();
  NSLog(@"%d", age);	
  // 输出 2
  ```

- 修改为 .cpp 文件后，与之前的主要变化包括：

  ```c++
  void block_variable() {
    	//****局部变量被封装成一个结构体 __Block_byref_a_0****
      __attribute__((__blocks__(byref))) __Block_byref_a_0 a = {(void*)0,(__Block_byref_a_0 *)&a, 0, sizeof(__Block_byref_a_0), 1};
      //****传递结构体 __Block_byref_a_0 到构造函数****
      void (*block)(void) = ((void (*)())&__block_variable_block_impl_0((void *)__block_variable_block_func_0, &__block_variable_block_desc_0_DATA, (__Block_byref_a_0 *)&a, 570425344));
  }
  ```

  - 局部变量被封装成一个结构体 `__Block_byref_a_0`：

  ```c++
  struct __Block_byref_a_0 {
    void *__isa;
  __Block_byref_a_0 *__forwarding;
   int __flags;
   int __size;
   int a;
  };
  ```

  - block 的类型 `__block_variable_block_impl_0` 结构体中增加了指针成员变量 `__Block_byref_a_0`。

  ```c++
  struct __block_variable_block_impl_0 {
    struct __block_impl impl;
    struct __block_variable_block_desc_0* Desc;
    //****指针成员变量****
    __Block_byref_a_0 *a; // by ref
    __block_variable_block_impl_0(void *fp, struct __block_variable_block_desc_0 *desc, __Block_byref_a_0 *_a, int flags=0) : a(_a->__forwarding) {
      impl.isa = &_NSConcreteStackBlock;
      impl.Flags = flags;
      impl.FuncPtr = fp;
      Desc = desc;
    }
  };
  ```

  -  block 块中的代码的封装。

  ```c++
  static void __block_variable_block_func_0(struct __block_variable_block_impl_0 *__cself) {
    __Block_byref_a_0 *a = __cself->a; // bound by ref
    //****修改局部变量****
    (a->__forwarding->a) = 2;
  }
  ```

- 简而言之：**`__block` 修饰的变量被转换为结构体，通过指针传递到 block 结构体中。在 block 块方法中，通过  `__forwarding` 指针可以找到变量的内存地址，通过修改内存地址上保存的值进而修改变量的值。使用变量时，将获取变量此刻运行时的值，而不是定义时的快照。**以上结论不区分环境是 ARC 还是 MRC。

- `__forwarding` 指针：

  - 当 block 在栈中时， `__forwarding` 指针指向转换结构体自己。
  - 当 block 被复制到堆中时，栈中的转换结构体也会被复制到堆中一份，而此时栈中的转换结构体中的 `__forwarding` 指针指向的就是堆中的转换结构体，堆中复制的转换结构体内的 `__forwarding `指针依然指向自己。
  - 因此，不管 block 是被复制到堆上还是在栈上，都可以通过 `a->__forwarding->a` 访问到被 `__block` 修饰的变量。

  ![](https://tva1.sinaimg.cn/large/008eGmZEgy1gmu77qtyhjj30ze0okdqj.jpg)

# 内存管理

- 当 block 在栈上时，不会对捕获的对象变量进行强引用（不管 MRC 环境还是 ARC 环境都如此，以下如无特别说明，都指两个环境）。

- 当 block 在堆上时，根据捕获的对象变量的修饰词（`__weak`、`__strong`、`__unsafe_unretained`）来处理对象的强弱引用和引用计数。

  ```c++
  // block结构体
  struct __xxx_block_impl_0 {
    STObject *o; // MRC: STObject *o
    STObject *__strong o; // ARC: STObject *o
    STObject *__strong strongO; // __strong STObject *strongO
    STObject *__weak weakO; // __weak STObject *weakO
    STObject *__unsafe_unretained unretainedO; // __unsafe_unretained STObject *unretainedO
  };
  ```

- 当捕获对象变量时，block 中的描述结构体 `__xxx_block_desc_0` 中多了名为 `copy` 和 `dispose` 的函数指针；

  - 当 block 从栈拷贝到堆时，调用 `_Block_object_assign` 函数。

  - 当 block 从堆内存释放时，调用 `_Block_object_dispose` 函数。

  - 最后一个参数决定了后续处理对象的引用的方式：

  | 枚举                  | 值   | 内存处理                                                   |
  | --------------------- | ---- | ---------------------------------------------------------- |
  | BLOCK_FIELD_IS_OBJECT | 3    | OC 对象类型                                                |
  | BLOCK_FIELD_IS_BLOCK  | 7    | Block 变量                                                 |
  | BLOCK_FIELD_IS_BYREF  | 8    | `__block` 修饰变量后产生的结构体                           |
  | BLOCK_FIELD_IS_WEAK   | 16   | `__weak` 修饰的变量                                        |
  | BLOCK_BYREF_CALLER    | 128  | 在处理内部对象内存时加上的额外标记，配合以上枚举值一起使用 |

  ```c++
  static struct __xxx_block_desc_0 {
    size_t reserved;
    size_t Block_size;
    // copy函数指针
    void (*copy)(struct __xxx_block_impl_0*, struct __xxx_block_impl_0*);
    // dispose函数指针
    void (*dispose)(struct __xxx_block_impl_0*);
  } __class_variable_block_desc_0_DATA = { 0, sizeof(struct __xxx_block_impl_0), __xxx_block_copy_0, __xxx_block_dispose_0};
  
  // copy函数实现
  static void __xxx_block_copy_0(struct __xxx_block_impl_0*dst, struct __xxx_block_impl_0*src) {_Block_object_assign((void*)&dst->o, (void*)src->o, 3/*BLOCK_FIELD_IS_OBJECT*/);}
  
  // dispose函数实现
  static void __xxx_block_dispose_0(struct __xxx_block_impl_0*src) {_Block_object_dispose((void*)src->o, 3/*BLOCK_FIELD_IS_OBJECT*/);}
  ```

- ARC 环境中，当对象变量用 `__block` 修饰时，block 结构体对转换的变量结构体总是强引用。但变量结构体是否强引用对象，根据捕获的对象变量的修饰词（`__weak`、`__strong`、`__unsafe_unretained`）来决定。

  ```c++
  // block结构体
  struct __xxx_block_impl_0 {
    __Block_byref_o_2 *o; // // STObject *o
    __Block_byref_strongO_3 *strongO; // __strong STObject *strongO
    __Block_byref_weakO_4 *weakO; // __weak STObject *weakO
    __Block_byref_unretainedO_5 *unretainedO; // __unsafe_unretained STObject *unretainedO
  };
  
  // 转换结构体
  struct __Block_byref_o_2 {
   STObject *__strong o;
  };
  struct __Block_byref_strongO_3 {
   STObject *__strong strongO;
  };
  struct __Block_byref_weakO_4 {
   STObject *__weak weakO;
  };
  struct __Block_byref_unretainedO_5 {
   STObject *__unsafe_unretained unretainedO;
  };
  ```

- MRC 环境中，当对象用 `__block` 修饰时，block 不会对对象强引用，即使 block 已经在被 copy 到堆上—— 在 MRC 环境下，`__block` 根本不会对指针所指向的对象执行 `copy` 操作，而只是把指针进行复制。

- **引用和释放流程**：当 `__block` 修饰对象变量时，变量转换的结构体中会添加两个方法指针： `__Block_byref_id_object_copy`  和 `__Block_byref_id_object_dispose`。

  ```c++
  struct __Block_byref_o_1 {
    void *__isa;
  __Block_byref_o_1 *__forwarding;
   int __flags;
   int __size;
   void (*__Block_byref_id_object_copy)(void*, void*);
   void (*__Block_byref_id_object_dispose)(void*);
   STObject *__strong o;
  };
  
  // +40就是指向 STObject *__strong o;
  static void __Block_byref_id_object_copy_131(void *dst, void *src) {
   _Block_object_assign((char*)dst + 40, *(void * *) ((char*)src + 40), 131);
  }
  // 131 = BLOCK_BYREF_CALLER | BLOCK_FIELD_IS_OBJECT
  static void __Block_byref_id_object_dispose_131(void *src) {
   _Block_object_dispose(*(void * *) ((char*)src + 40), 131);
  }
  ```

  - 当 blcok 被复制到堆上时，调用栈如下，从而对 `__block` 变量形成强引用。

  ```c++
  copy -> __Block_byref_id_object_copy -> _Block_object_assign
  ```

  - 当 block 从堆中移除的话，调用栈如下，从而对 `__block` 变量进行引用释放。

  ```
  dispose -> __Block_byref_id_object_dispose -> _Block_object_dispose
  ```

## 循环引用

- block 循环引用原因：一个对象 A 有 block 类型的属性，从而持有这个 block，如果 block 的代码块中使用到这个对象 A ，或者是 A 对象的属性，会使 block也持有 A 对象，导致两者互相持有，不能在作用域结束后正常释放。

  ```objective-c
  self.block = ^(){
      NSLog(@"%@", self.name);
  };
  ```

- 三种解决方案：

  - block 中使用 `__weak` 修饰的对象 A，使其弱引用对象 A；

  ```objc
  __weak typeof(self) weakSelf = self;
  self.block = ^(){
      NSLog(@"%@", weakSelf.name);
  };
  ```

  > **MRC 环境不支持 `__weak`，与之对应的，应该使用 `__block` 或 `__unsafe_unretained`。**

  -  block 中使用 `__block` 修饰的对象 A，内部使用完成后设置对象为 `nil`，block 必须执行一次；

  ```objective-c
  __block Stone *blockSelf = self;
  self.block = ^(){
      NSLog(@"%@", blockSelf.name);
      blockSelf = nil;
  };
  self.block();
  ```

  - 将对象 A 以参数的形式传入 block，block 就不会捕获该对象 A；

  ```objective-c
  self.myBlock = ^(Stone *o){
      NSLog(@"%@", o.name);
  };
  ```

- 在 block 内部重新使用 `__strong` 修饰 `self` 变量，从而在 block 内部有一个强指针 `strongSelf` 指向 `weakSelf`，避免在 block 调用的时候 `weakSelf` 已经被销毁（多线程应用中）。

  - `strongSelf` 是一个自动变量，当 block 执行完毕就会释放。

  ```objective-c
  __weak typeof(self) weakSelf = self;
  person.block = ^{
      __strong typeof(weakSelf) strongSelf = weakSelf;
      //...
  };
  ```

# 签名

- 利用 `NSInvocation` 执行 block 时，关键点就是获取 block 的方法签名。

- 定义类似于 block 的结构体。

  ```c++
  // flags 取值
  enum {
    BLOCK_HAS_COPY_DISPOSE =  (1 << 25), // compiler
    BLOCK_HAS_SIGNATURE  =    (1 << 30)  // compiler
  };
  
  struct Block_layout {
      void *isa;
      int flags; // block属性的标识符
      int reserved;
      void (*invoke)(void *, ...); // 块代码的函数指针
      struct {
          unsigned long int reserved;
          unsigned long int size;
          // requires BLOCK_HAS_COPY_DISPOSE
          void (*copy)(void *dst, const void *src);
          void (*dispose)(const void *);
          // requires BLOCK_HAS_SIGNATURE
          const char *signature;
          const char *layout;
      } *descriptor;
  };
  ```

- 通过 bridge 桥接将 OC 形式的 block 转化为结构体形式的 block。

  ```objective-c
  int (^originalBlock)(int, int ) = ^int(int a, int b) {
      NSLog(@"Block called %d %d", a, b);
      return a + b;
  };
  
  struct Block_layout *block = (struct Block_layout *)(__bridge void *)originalBlock;
  ```

- 通过指向 `invoke` 函数指针直接指向 block 代码块。

  ```objective-c
  int (*blockIMP)(void *, int, int) = (int (*)(void *, int, int))(block->invoke);
  int result = blockIMP(block, 1, 2);
  NSLog(@"直接执行block %d", result);
  // Block called 1 2
  // 直接执行block 3
  ```

- 通过 `NSInvocation` 对象执行 block 代码块。

  ```objective-c
  // 没有签名，直接返回空
  if (!(block->flags & BLOCK_HAS_SIGNATURE)) {
      return ;
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
  
  // Block called 3 4
  // NSInvocation执行block 7
  ```

  
