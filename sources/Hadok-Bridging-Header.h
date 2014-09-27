//
//  Use this file to import your target's public headers that you would like to expose to Swift.
//

#import <UIKit/UIKit.h>
#import "sqlite3.h"

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);