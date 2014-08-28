//
//  SwiftSQL.swift
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import Foundation

class CamembertModel :NSObject {
    
    var _nameTable :String! = nil
    var id :Int? = nil
    
    func setId(id :Int) {
        self.id = id
    }
    
    func push() {
        if self.id != nil {
            return Void()
        }
        var requestPush = "INSERT INTO " + self._nameTable + " ("

        for var index = 1; index < reflect(self).count; index++ {
            switch index {
            case reflect(self).count - 1 : requestPush += reflect(self)[index].0 + ")"
            default: requestPush += reflect(self)[index].0 + ", "
            }
        }
        requestPush += " VALUES ("
        for var index = 1; index < reflect(self).count; index++ {
            var currentValue = reflect(self)[index].1.value
            
            switch currentValue {
            case let v where currentValue as? TEXT: requestPush += "\"\(currentValue)\""
            default: requestPush += "\(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestPush += ");"
            default: requestPush += ", "
            }
        }
        camembertExecSqlite3(DataAccess.access.dataAccess, requestPush.bridgeToObjectiveC().cString())
        self.id = Int(sqlite3_last_insert_rowid(DataAccess.access.dataAccess))
    }
    
    func update() {
        if self.id == -1 {
            return Void()
        }
        var requestUpdate :String = "UPDATE \(self._nameTable) SET "
        
        for var index = 1; index < reflect(self).count; index++ {
            var currentValue = reflect(self)[index].1.value
            
            switch currentValue {
            case let v where currentValue as? TEXT: requestUpdate += "\(reflect(self)[index].0) = \"\(currentValue)\""
            default: requestUpdate += "\(reflect(self)[index].0) = \(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestUpdate += " WHERE id = \(self.id);"
            default: requestUpdate += ", "
            }
        }
        camembertExecSqlite3(DataAccess.access.dataAccess, requestUpdate.bridgeToObjectiveC().cString())
    }
    
    func remove() {
        var requestDelete :String = "DELETE FROM \(self._nameTable) WHERE id=\(self.id)"
        camembertExecSqlite3(DataAccess.access.dataAccess, requestDelete.bridgeToObjectiveC().cString())
        self.id = -1
    }
    
    func getSchemaTable() -> String[]! {
        var arraySirng :String[] = []
        
        for var index = 1; index < reflect(self).count; index++ {
            let reflectionClass = reflect(self)[index]
            let currentValue = reflectionClass.1.value

            switch currentValue {
            case let v where currentValue as? INTEGER:
                arraySirng.append("\(reflectionClass.0) INTEGER")
            case let v where currentValue as? REAL:
                arraySirng.append("\(reflectionClass.0) REAL")
            case let v where currentValue as? TEXT:
                arraySirng.append("\(reflectionClass.0) TEXT")
            default: return nil
            }
        }
        return arraySirng
    }
    
    func isTableExist() -> Bool {
        for currentTable in Camembert.getListTable() {
            if currentTable == self._nameTable {
                return true
            }
        }
        return false
    }
    
    class func getNameTable(inout tmpNameTable :String) -> String {
        let parseString = "0123456789"
        
        for currentNumberParse in parseString {
            var parseName = tmpNameTable.componentsSeparatedByString(String(currentNumberParse))
            if parseName.count > 0 {
                tmpNameTable = parseName[parseName.count - 1]
            }
        }
        return tmpNameTable
    }
    
    func _initNameTable() {
        var tmpNameTable = NSString(CString: object_getClassName(self)) as String
        self._nameTable = CamembertModel.getNameTable(&tmpNameTable)
    }
    
    func sendRequest(inout ptrRequest :COpaquePointer, request :String) -> Bool {
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            request.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
            return false
        }
        return true
    }
    
    func createTable() -> Bool {
        if self.isTableExist() == false {
            var requestCreateTable :String = "CREATE TABLE " + self._nameTable + " (id INTEGER PRIMARY KEY AUTOINCREMENT, "
            if let configurationTable = self.getSchemaTable() {
                for var index = 0; index < configurationTable.count; index++ {
                    switch index {
                    case configurationTable.count - 1: requestCreateTable += configurationTable[index]
                    default: requestCreateTable += configurationTable[index] + ", "
                    }
                }
                requestCreateTable += ");"
                var request :COpaquePointer = nil
                camembertExecSqlite3(DataAccess.access.dataAccess, requestCreateTable.bridgeToObjectiveC().cString())
            }
        }
        return true
    }
    
    class func numberElement() -> Int {
        var tmpNameTable = NSString(CString: class_getName(self)) as String
        var requestNumberlement :String = "SELECT COUNT(*) FROM \(CamembertModel.getNameTable(&tmpNameTable));"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestNumberlement.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
            return 0
        }
        if sqlite3_step(ptrRequest) == SQLITE_ROW {
            return Int(sqlite3_column_int(ptrRequest, 0))
        }
        return 0
    }
    
    func _initWithId(id :Int) {
        var requestInit :String = "SELECT * FROM \(self._nameTable) WHERE id=\(id);"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestInit.bridgeToObjectiveC().cString(), -1, &ptrRequest, nil) != SQLITE_OK {
            return Void()
        }

        if sqlite3_step(ptrRequest) == SQLITE_ROW {
            for var index = 0; index < reflect(self).count; index++ {
                if index == 0 {
                    self.id = Int(sqlite3_column_int(ptrRequest, 0))
                }
                else {
                    var currentTypeData = sqlite3_column_type(ptrRequest, CInt(index))
                    switch currentTypeData {
                    case SQLITE_INTEGER:
                        self.setValue((Int(sqlite3_column_int(ptrRequest, CInt(index))) as AnyObject),
                            forKey: reflect(self)[index].0)
                    case SQLITE_FLOAT:
                        self.setValue((Float(sqlite3_column_double(ptrRequest, CInt(index))) as AnyObject),
                            forKey: reflect(self)[index].0)
                    case SQLITE_TEXT:
                        var stringValue = NSString(UTF8String: CString(sqlite3_column_text(ptrRequest, CInt(index))))
                        self.setValue((String(stringValue) as AnyObject), forKey: reflect(self)[index].0)
                    default: Void()
                    }
                }
            }
        }
    }
    
    init() {
        super.init()
        self._initNameTable()
        self.createTable()
    }
    
    init(id :Int) {
        super.init()
        self._initNameTable()
        self.createTable()
        self._initWithId(id)
    }
}