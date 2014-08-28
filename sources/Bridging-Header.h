//
//  Bridging-Header.h
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);