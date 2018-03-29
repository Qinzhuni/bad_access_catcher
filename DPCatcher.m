//
//  DPCatcher.m
//  InterviewDemo
//
//  Created by Lincoln on 2018/3/29.
//  Copyright © 2018年 Lincoln. All rights reserved.
//

#import "DPCatcher.h"
#import <objc/runtime.h>

@implementation DPCatcher

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"发现objc野指针:%s::%p=>%@",class_getName(self.origClass),self,NSStringFromSelector(aSelector));
    abort();
    return nil;
}
 
-(void)dealloc{
    NSLog(@"发现objc野指针:%s::%p=>%@",class_getName(self.origClass),self,@"dealloc");
    abort();
}

-(oneway void)release{
    NSLog(@"发现objc野指针:%s::%p=>%@",class_getName(self.origClass),self,@"release");
    abort();
}
 
- (instancetype)autorelease{
    NSLog(@"发现objc野指针:%s::%p=>%@",class_getName(self.origClass),self,@"autorelease");
    abort();
}

@end
