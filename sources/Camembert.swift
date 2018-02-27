
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
typealias DATE_TIME = Date
typealias BIT = Bool


enum Operator {
    case LargerThan,
    LargerOrEqual,
    SmallerThan,
    SmallerOrEqual,
    EqualsTo,
    IsNull,
    NotNull
}

enum OrderOperator{
    case Ascending,
    Descending
}

enum Select {
    case SelectAll(OrderOperator, String)
    case CustomRequest(String)
    case Limit(Int, OrderOperator, String)
    case Between(Int, Int, OrderOperator, String)
    case Where(String, Operator, Any, OrderOperator, String)
}

class DataAccess {
    var dataAccess :OpaquePointer? = nil
    var nameDataBase: String? = nil
    private var _dbpath: String? = nil;
    var DbPath: String? {
        get{
            return _dbpath;
        }
        set (value){
            var isDir = ObjCBool(true)
            FileManager.default.fileExists(atPath: value!,
                                           isDirectory: &isDir)
            if !FileManager.default.fileExists(atPath: value!,
                                               isDirectory: &isDir){
                do {
                    try FileManager.default.createDirectory(atPath: value!,
                                                            withIntermediateDirectories: true,
                                                            attributes: nil)
                }
                catch {
                    print("DataAccess function raised an exception")
                }
                
            }
            _dbpath = value;
        }
    }

    class var access :DataAccess {
    struct Static {
        static let instance : DataAccess = DataAccess()
        }
        return Static.instance
    }
}

class Camembert {
    
    class func initDataBase(_ nameDatabase :String) -> Bool {
        let documentDirectory :String = NSSearchPathForDirectoriesInDomains(
            .documentDirectory, .userDomainMask, true)[0] as String
        
        let pathDatabase = documentDirectory + "/" + nameDatabase
        let ret = sqlite3_open(pathDatabase.cString(using: String.Encoding.utf8)!,
                               &DataAccess.access.dataAccess)
        
        if ret != SQLITE_OK {
            return createDataBase(nameDatabase)
        }
        DataAccess.access.nameDataBase = nameDatabase
        return true
    }
    
    class func initDataBase(_ databaseFolder: String,
                            nameDatabase :String) -> Bool{
        DataAccess.access.DbPath = databaseFolder;
        
        let ret = sqlite3_open(databaseFolder.cString(using: String.Encoding.utf8)!,
                               &DataAccess.access.dataAccess)
        if ret != SQLITE_OK {
            return createDataBase(databaseFolder,
                                  nameDatabase: nameDatabase)
        }
        DataAccess.access.nameDataBase = nameDatabase
        return true;
    }

    class func createDataBase(_ nameDatabase: String) -> Bool {
        let documentDirectory :String = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true)[0] as String
        
        let pathDatabase = documentDirectory + "/" + nameDatabase
        
        if sqlite3_open_v2(pathDatabase.cString(using: String.Encoding.utf8)!,
                           &DataAccess.access.dataAccess,
                           (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE),
                           nil) != SQLITE_OK {

                DataAccess.access.dataAccess = nil
                return false
        }
        DataAccess.access.nameDataBase = nameDatabase
        return true
    }
    
    class func createDataBase(_ databaseFolder: String,
                              nameDatabase: String) -> Bool {
        if DataAccess.access.DbPath == nil {
            DataAccess.access.DbPath = databaseFolder;
        }
        
        let pathDatabase = databaseFolder + "/" + nameDatabase
        
        if sqlite3_open_v2(pathDatabase.cString(using: String.Encoding.utf8)!,
                           &DataAccess.access.dataAccess,
                           (SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE),
                           nil) != SQLITE_OK {
                
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

    func getObjectsWithQuery<T: CamembertModel>(_ query :String,
                             table :String) -> [T] {
        var ptrRequest :OpaquePointer? = nil
        var objects :Array<T> = []
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              query.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return [T]()
        }
        while (sqlite3_step(ptrRequest) == SQLITE_ROW) {
            let currentObject: T = camembertCreateObject(table) as! T
            
            currentObject.setId(Int(sqlite3_column_int(ptrRequest,
                                                                            0)))
            for index in 1 ..< Int(sqlite3_column_count(ptrRequest)) {
                let name = sqlite3_column_name(ptrRequest,
                                               CInt(index))
                let columName = String(cString: name!,
                                       encoding: String.Encoding.utf8)!
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    currentObject.setValue((Int(sqlite3_column_int(ptrRequest,
                                                                   CInt(index))) as AnyObject),
                                           forKey: columName)
                case SQLITE_FLOAT:
                    if currentObject.isDate(columName) {
                        currentObject.setValue(Date(timeIntervalSince1970:TimeInterval(sqlite3_column_double(ptrRequest,
                                                                                                             CInt(index)))),
                                               forKey: columName)
                    } else {
                        currentObject.setValue((Float(sqlite3_column_double(ptrRequest,
                                                                            CInt(index))) as AnyObject),
                                               forKey: columName)
                    }
                case SQLITE_TEXT:
                    let text = sqlite3_column_text(ptrRequest,
                                                   CInt(index))
                    let stringValue = String(cString:text!)
                    currentObject.setValue(stringValue,
                                           forKey: columName)
                default: Void()
                }
            }
            objects.append(currentObject)
        }
        sqlite3_finalize(ptrRequest);
        return objects
    }
    
    class func execQuery(query :String) -> OpaquePointer? {
        var ptrRequest :OpaquePointer? = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              query.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return nil
        }
        sqlite3_finalize(ptrRequest);
        return ptrRequest
    }
    
    class func getListTable() -> [String] {
        var tables :[String] = []
        var ptrRequest :OpaquePointer? = nil
        let requestListTables :String = "SELECT name FROM sqlite_master WHERE type='table';"
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              requestListTables.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return tables
        }
        while sqlite3_step(ptrRequest) == SQLITE_ROW {
            tables.append(String(cString:sqlite3_column_text(ptrRequest,
                                                             0)))
        }
        sqlite3_finalize(ptrRequest);
        return tables
    }
}
