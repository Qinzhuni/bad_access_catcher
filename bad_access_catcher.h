//
//  bad_access_catcher.h
//  InterviewDemo
//
//  Created by Lincoln on 2018/3/29.
//  Copyright © 2018年 Lincoln. All rights reserved.
//

#ifndef bad_access_catcher_h
#define bad_access_catcher_h

#include <stdio.h>
#include <stdbool.h>

bool init_safe_free();
void free_some_mem(size_t freeNum);

#endif /* bad_access_catcher_h */
