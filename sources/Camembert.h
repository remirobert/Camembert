//
//  Camembert.h
//  CamemberDebug
//
//  Created by Remi Robert on 23/10/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

#ifndef CamemberDebug_Camembert_h
#define CamemberDebug_Camembert_h

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "sqlite3.h"
#import <objc/runtime.h>

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);

#endif
