//
//  bad_access_catcher.c
//  InterviewDemo
//
//  Created by Lincoln on 2018/3/29.
//  Copyright © 2018年 Lincoln. All rights reserved.
//

#include "bad_access_catcher.h"
#import <CoreFoundation/CoreFoundation.h>
#import <dlfcn.h>
#import "fishhook.h"
#import <malloc/malloc.h>
#import "queue.h"
#import <objc/runtime.h>
#import "DPCatcher.h"

static void (*orig_free)(void*);
void safe_free(void*);
struct DSQueue* _unfreeQueue=NULL;//用来保存自己偷偷保留的内存:1这个队列要线程安全或者自己加锁;2这个队列内部应该尽量少申请和释放堆内存。
int unfreeSize=0;//用来记录我们偷偷保存的内存的大小
CFMutableSetRef registeredClasses;
Class sDPCatchIsa;
size_t sDPCatchSize;

#define MAX_STEAL_MEM_SIZE 1024*1024*100//最多存这么多内存，大于这个值就释放一部分
#define MAX_STEAL_MEM_NUM 1024*1024*10//最多保留这么多个指针，再多就释放一部分
#define BATCH_FREE_NUM 100//每次释放的时候释放指针数量

bool init_safe_free()
{
    registeredClasses = CFSetCreateMutable(NULL, 0, NULL);
    
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    for (unsigned int i = 0; i < count; i++) {
        CFSetAddValue(registeredClasses, classes[i]);
    }
    free(classes);
    classes=NULL;
    
    sDPCatchIsa=objc_getClass("DPCatcher");
    
    sDPCatchSize=class_getInstanceSize(sDPCatchIsa);
    
    _unfreeQueue = ds_queue_create(MAX_STEAL_MEM_NUM);
    orig_free=(void(*)(void*))dlsym(RTLD_DEFAULT, "free");
    rebind_symbols((struct rebinding[]){{"free", (void*)safe_free}}, 1);
    return true;
}

void safe_free(void* p) {
    int unFreeCount=ds_queue_length(_unfreeQueue);
    if (unFreeCount>MAX_STEAL_MEM_NUM*0.9 || unfreeSize>MAX_STEAL_MEM_SIZE) {
        free_some_mem(BATCH_FREE_NUM);
    }else {
        size_t memSiziee=malloc_size(p);
        if (memSiziee>sDPCatchSize) {//有足够的空间才覆盖
            id obj=(id)p;
            Class origClass=object_getClass(obj); //判断是不是objc对象 ，registeredClasses里面有所有的类，如果可以查到，说明是objc类
            if (origClass && CFSetContainsValue(registeredClasses, origClass)) {
                memset(obj, 0x55, memSiziee);
                memcpy(obj, &sDPCatchIsa, sizeof(void*));//把我们自己的类的isa复制过去
                
                DPCatcher* bug=(DPCatcher*)p;
                bug.origClass=origClass;
            }else{
                memset(p, 0x55, memSiziee);
            }
            
        }else{
            memset(p, 0x55, memSiziee);
        }
        __sync_fetch_and_add(&unfreeSize,(int)memSiziee);
        ds_queue_put(_unfreeQueue, p);
    }
    return;
}

//系统内存警告的时候调用这个函数释放一些内存
void free_some_mem(size_t freeNum) {
    size_t count=ds_queue_length(_unfreeQueue);
    freeNum=freeNum>count?count:freeNum;
    for (int i=0; i<freeNum; i++) {
        void* unfreePoint=ds_queue_get(_unfreeQueue);
        size_t memSiziee=malloc_size(unfreePoint);
        __sync_fetch_and_sub(&unfreeSize,(int)memSiziee);
        orig_free(unfreePoint);
    }
}
