//
//  Camembert.swift
//  SwiftSQL
//
//  Created by Remi Robert on 28/08/14.
//  Modified by Omar Bizreh on 11/1/16.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

//! Project version number for Camembert.
FOUNDATION_EXPORT double CamembertVersionNumber;

//! Project version string for Camembert.
FOUNDATION_EXPORT const unsigned char CamembertVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <Camembert/PublicHeader.h>



BOOL camembertExecSqlite3(void *ptrSqlite3, const char *request);
id camembertCreateObject(NSString *nameClass);


