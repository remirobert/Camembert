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

enum Select {
    case SelectAll
    case CustomRequest(String)
    case Limit(Int)
    case Between(Int, Int)
}

class DataAccess {
    var dataAccess :COpaquePointer = nil
    var nameDataBase: String? = nil
    
    class var access :DataAccess {
    struct Static {
        static let instance : DataAccess = DataAccess()
        }
        return Static.instance
    }
}

class Camembert {
    class func initDataBase(nameDatabase :String) -> Bool {
        let documentDirectory :String = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let pathDatabase = documentDirectory + "/" + nameDatabase
        
        let ret = sqlite3_open(pathDatabase.cStringUsingEncoding(NSUTF8StringEncoding)!,
            &DataAccess.access.dataAccess)
        
        if ret != SQLITE_OK {
            return createDataBase(nameDatabase)
        }
        DataAccess.access.nameDataBase = nameDatabase
        return true
    }

    class func createDataBase(nameDatabase: String) -> Bool {
        let documentDirectory :String = NSSearchPathForDirectoriesInDomains(
            .DocumentDirectory, .UserDomainMask, true)[0] as String
        
        let pathDatabase = documentDirectory + "/" + nameDatabase
        
        if sqlite3_open_v2(pathDatabase.cStringUsingEncoding(NSUTF8StringEncoding)!,
            &DataAccess.access.dataAccess, (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE), nil) != SQLITE_OK {

                DataAccess.access.dataAccess = nil
                return false
        }
        DataAccess.access.nameDataBase = nameDatabase
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

    func getObjectsWithQuery(query :String, table :String) -> [AnyObject]! {
        var ptrRequest :COpaquePointer = nil
        var objects :Array<AnyObject> = []
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return nil
        }
        while (sqlite3_step(ptrRequest) == SQLITE_ROW) {
            var currentObject :AnyObject! = camembertCreateObject(table) as AnyObject
            
            (currentObject as CamembertModel).setId(Int(sqlite3_column_int(ptrRequest, 0)))
            for var index = 1; index < Int(sqlite3_column_count(ptrRequest)); index++ {
                let columName :String = NSString(CString: sqlite3_column_name(ptrRequest,
                    CInt(index)), encoding: NSUTF8StringEncoding)!
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    currentObject.setValue((Int(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_FLOAT:
                    currentObject.setValue((Float(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_TEXT:
                    var stringValue = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(ptrRequest, CInt(index))))
                    currentObject.setValue(stringValue, forKey: columName)
                default: Void()
                }
            }
            objects.append(currentObject)
        }
        sqlite3_finalize(ptrRequest);
        return objects
    }
    
    class func execQuery(query :String) -> COpaquePointer {
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            query.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return nil
        }
        sqlite3_finalize(ptrRequest);
        return ptrRequest
    }
    
    class func getListTable() -> [String] {
        var tables :[String] = []
        var ptrRequest :COpaquePointer = nil
        var requestListTables :String = "SELECT name FROM sqlite_master WHERE type='table';"
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestListTables.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return tables
        }
        while sqlite3_step(ptrRequest) == SQLITE_ROW {
            tables.append(String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(ptrRequest, 0)))!)
        }
        sqlite3_finalize(ptrRequest);
        return tables
    }
}
