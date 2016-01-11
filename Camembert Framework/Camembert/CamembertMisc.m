//
//  ExecSqlite3.m
//  SwiftSQL
//
//  Created by Remi Robert on 25/08/14.
//  Modified by Omar Bizreh on 11/1/16.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

#import "Camembert.h"
#import "sqlite3.h"

BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request) {
    char *msgErr;
    if (sqlite3_exec(ptrSqlite3, request, NULL, nil, &msgErr) != SQLITE_OK) {
        if (msgErr != nil)
            NSLog(@"Error exec sqlite3 statement %s", msgErr);
        else
            NSLog(@"Error exec sqlite3 statement");
        return false;
    }
    return true;
}

id camembertCreateObject(NSString *nameClass) {
    NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];
    NSString *classStringName = [NSString stringWithFormat:@"_TtC%lu%@%lu%@", (unsigned long)appName.length,
                                 appName, (unsigned long)nameClass.length, nameClass];
    
    Class customClass = NSClassFromString(classStringName);
    if (customClass == nil) {
        return nil;
    }
    return [[customClass alloc] init];
}