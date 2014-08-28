//
//  Camembert.swift
//  SwiftSQL
//
//  Created by Remi Robert on 28/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import Foundation


typealias INTEGER = Int
typealias REAL = Float
typealias TEXT = String
typealias BLOB = NSData
typealias ID = Int

class DataAccess {
    var dataAccess :COpaquePointer = nil
    
    class var access :DataAccess {
    struct Static {
        static let instance : DataAccess = DataAccess()
        }
        return Static.instance
    }
}

class Camembert {
    class func createDataBase(nameDatabase :String) -> Bool {
        let documentDirectory :String = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let pathDatabase = documentDirectory + "/" + nameDatabase
        let ret = sqlite3_open(pathDatabase.bridgeToObjectiveC().cString(),
            &DataAccess.access.dataAccess)
        
        if ret != SQLITE_OK {
            DataAccess.access.dataAccess = nil
            NSLog("[FAIL] Open dataBase", nil)
            return false
        }
        NSLog("[OK] Open dataBase", nil)
        return true
    }
    
    class func closeDataBase() -> Bool {
        if sqlite3_close(DataAccess.access.dataAccess) == SQLITE_OK {
            DataAccess.access.dataAccess = nil
            return true
        }
        DataAccess.access.dataAccess = nil
        return false
    }
    
    class func removeTable(tableName :String) {
        var requestRemove :String = "DROP TABLE IF EXISTS \(tableName);"
        
        camembertExecSqlite3(DataAccess.access.dataAccess, requestRemove.bridgeToObjectiveC().cString())
    }
    
    class func getObjectsWithQuery(query :String, table :String) -> AnyObject[]! {
        var ptrRequest :COpaquePointer = nil
        var objects :Array<AnyObject> = []
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            query.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
                return nil
        }
        while (sqlite3_step(ptrRequest) == SQLITE_ROW) {
            var currentObject :AnyObject! = camembertCreateObject(table) as AnyObject
            
            (currentObject as CamembertModel).setId(Int(sqlite3_column_int(ptrRequest, 0)))
            for var index = 1; index < Int(sqlite3_column_count(ptrRequest)); index++ {
                let columName :String = NSString(CString: sqlite3_column_name(ptrRequest, CInt(index)))
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    currentObject.setValue((Int(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_FLOAT:
                    currentObject.setValue((Float(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_TEXT:
                    var stringValue = NSString(UTF8String: CString(sqlite3_column_text(ptrRequest, CInt(index))))
                    currentObject.setValue(stringValue, forKey: columName)
                default: Void()
                }
            }
            objects.append(currentObject)
        }
        return objects
    }
    
    class func execQuery(query :String) -> COpaquePointer {
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            query.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
                return nil
        }
        return ptrRequest
    }
    
    class func getListTable() -> String[] {
        var tables :String[] = []
        var ptrRequest :COpaquePointer = nil
        var requestListTables :String = "SELECT name FROM sqlite_master WHERE type='table';"
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestListTables.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
                return tables
        }
        while sqlite3_step(ptrRequest) == SQLITE_ROW {
            tables.append(NSString(UTF8String: CString(sqlite3_column_text(ptrRequest, 0))))
        }
        return tables
    }
}
