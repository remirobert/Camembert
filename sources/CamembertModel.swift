//
//  SwiftSQL.swift
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import Foundation

class CamembertModel :NSObject {
    
    private var nameTable :String! = nil
    var id :Int? = nil
    
    func setId(id :Int) {
        self.id = id
    }
    
    
    
    private class func openConnection() {
        Camembert.closeDataBase()
        if let dbFolder = DataAccess.access.DbPath {
            Camembert.initDataBase(dbFolder, nameDatabase: DataAccess.access.nameDataBase!)
        }else{
            Camembert.initDataBase(DataAccess.access.nameDataBase!)
        }
    }
    
    enum OperationResult{
        case Success, Error_DuplicatedID, Error_NoRecordFoundWithID, Error_GeneralFailure
    }
    
    func push() -> OperationResult{
        if self.id != nil {
            return OperationResult.Error_DuplicatedID;
        }
        CamembertModel.openConnection()
        var requestPush = "INSERT INTO " + self.nameTable + " ("
        
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
            case let v where (currentValue as? TEXT != nil): requestPush += "\"\(currentValue)\""
            case let v where (currentValue as? DATE_TIME != nil):
                let dateformatter = NSDateFormatter();
                dateformatter.dateFormat = "yyyy'-'MM'-'dd hh':'mm':'ss'";
                let date = (currentValue as NSDate)
                let result = dateformatter.dateFromString("\(date)")
                requestPush += "\"\(date)\""
                break;
            case let v where (currentValue as? BIT != nil):
                if (currentValue as Bool){
                    requestPush += "1";
                }else{
                    requestPush += "0";
                }
                break;
            default: requestPush += "\(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestPush += ");"
            default: requestPush += ", "
            }
        }
        let result = camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestPush.cStringUsingEncoding(NSUTF8StringEncoding)!)
        self.id = Int(sqlite3_last_insert_rowid(DataAccess.access.dataAccess))
        var opResult: OperationResult = OperationResult.Success
        if !result{
            opResult = OperationResult.Error_GeneralFailure
        }
        return opResult
    }
    
    func update() -> OperationResult {
        if self.id == -1 {
            return OperationResult.Error_NoRecordFoundWithID
        }
        CamembertModel.openConnection()
        var requestUpdate :String = "UPDATE \(self.nameTable) SET "
        
        for var index = 1; index < reflect(self).count; index++ {
            var currentValue = reflect(self)[index].1.value
            
            switch currentValue {
            case let v where (currentValue as? TEXT != nil): requestUpdate += "\(reflect(self)[index].0) = \"\(currentValue)\""
            case let v where (currentValue as? DATE_TIME != nil):
                let dateformatter = NSDateFormatter();
                dateformatter.dateFormat = Camembert.Date_Time_Format;
                let date = (currentValue as NSDate)
                let result = dateformatter.dateFromString("\(date)")
                requestUpdate += "\(reflect(self)[index].0) = \"\(result)\""
                break;
                
            case let v where (currentValue as? BIT != nil):
                let result = (currentValue as Bool) ? "1" : "0";
                requestUpdate += "\(reflect(self)[index].0) = \"\(result)\""
            default: requestUpdate += "\(reflect(self)[index].0) = \(currentValue)"
            }
            
            switch index {
            case reflect(self).count - 1: requestUpdate += " WHERE id = \(self.id!);"
            default: requestUpdate += ", "
            }
        }
        let result = camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestUpdate.cStringUsingEncoding(NSUTF8StringEncoding)!)
        var opResult = OperationResult.Success
        if !result{
            opResult = OperationResult.Error_GeneralFailure
        }
        return opResult;
    }
    
    func remove() -> OperationResult{
        if self.id == nil {
            return OperationResult.Error_NoRecordFoundWithID;
        }
        CamembertModel.openConnection()
        var requestDelete :String = "DELETE FROM \(self.nameTable) WHERE id=\(self.id!)"
        
        let result = camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestDelete.cStringUsingEncoding(NSUTF8StringEncoding)!)
        self.id = -1
        if !result{
            return OperationResult.Error_GeneralFailure
        }
        return OperationResult.Success
    }
    
    func getSchemaTable() -> [String]! {
        CamembertModel.openConnection()
        
        var arrayString :[String] = []
        
        for var index = 1; index < reflect(self).count; index++ {
            let reflectionClass = reflect(self)[index]
            let currentValue = reflectionClass.1.value
            
            switch currentValue {
            case let v where (currentValue as? INTEGER != nil):
                arrayString.append("\(reflectionClass.0) INTEGER")
            case let v where (currentValue as? REAL != nil):
                arrayString.append("\(reflectionClass.0) REAL")
            case let v where (currentValue as? TEXT != nil):
                arrayString.append("\(reflectionClass.0) TEXT")
            case let v where (currentValue as? DATE_TIME != nil):
                arrayString.append("\(reflectionClass.0) TEXT")
            case let v where (currentValue as? BIT != nil):
                arrayString.append("\(reflectionClass.0) INTEGER")
            default: return nil
            }
        }
        return arrayString
    }
    
    func isTableExist() -> Bool {
        CamembertModel.openConnection()
        
        for currentTable in Camembert.getListTable() {
            if currentTable == self.nameTable {
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
        CamembertModel.openConnection()
        
        var tmpNameTable = NSString(CString: object_getClassName(self), encoding: NSUTF8StringEncoding) as String
        self.nameTable = CamembertModel.getNameTable(&tmpNameTable).componentsSeparatedByString(".")[1]
    }
    
    func sendRequest(inout ptrRequest :COpaquePointer, request :String) -> Bool {
        CamembertModel.openConnection()
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            request.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return false
        }
        sqlite3_finalize(ptrRequest);
        return true
    }
    
    func createTable() -> Bool {
        CamembertModel.openConnection()
        
        if self.isTableExist() == false {
            var requestCreateTable :String = "CREATE TABLE " + self.nameTable + " (id INTEGER PRIMARY KEY AUTOINCREMENT, "
            if let configurationTable = self.getSchemaTable() {
                for var index = 0; index < configurationTable.count; index++ {
                    switch index {
                    case configurationTable.count - 1: requestCreateTable += configurationTable[index]
                    default: requestCreateTable += configurationTable[index] + ", "
                    }
                }
                requestCreateTable += ");"
                var request :COpaquePointer = nil
                camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
                    requestCreateTable.cStringUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        return true
    }
    
    class func numberElement() -> Int {
        CamembertModel.openConnection()
        
        var tmpNameTable = NSString(CString: class_getName(self), encoding: NSUTF8StringEncoding) as String
        tmpNameTable = tmpNameTable.componentsSeparatedByString(".")[1]
        var requestNumberlement :String = "SELECT COUNT(*) FROM \(CamembertModel.getNameTable(&tmpNameTable));"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestNumberlement.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return 0
        }
        if sqlite3_step(ptrRequest) == SQLITE_ROW {
            let number = Int(sqlite3_column_int(ptrRequest, 0))
            sqlite3_finalize(ptrRequest);
            return number
        }
        return 0
    }
    
    func _initWithId(id :Int) {
        CamembertModel.openConnection()
        
        var requestInit :String = "SELECT * FROM \(self.nameTable) WHERE id=\(id);"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestInit.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
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
                        var stringValue = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(ptrRequest, CInt(index))))
                        self.setValue((String(stringValue!) as AnyObject), forKey: reflect(self)[index].0)
                    default: Void()
                    }
                }
            }
        }
        sqlite3_finalize(ptrRequest);
    }
    
    class func getRawClassName() -> String? {
        let name = NSStringFromClass(self)
        let components = name.componentsSeparatedByString(".")
        return components.last
    }
    
    class func select(selectRequest select: Select) -> [AnyObject] {
        let camembert = Camembert()
        let table = getRawClassName()
        var requestSelect: String? = nil
        
        switch select {
        case .SelectAll:
            requestSelect = "SELECT * FROM \(table!)"
        case .Limit(let value):
            requestSelect = "SELECT * FROM \(table!) LIMIT \(value)"
        case .Between(let startValue, let endValue):
            requestSelect = "SELECT * FROM \(table!) WHERE ID BETWEEN \(startValue) AND \(endValue)"
        case .CustomRequest(let request):
            requestSelect = request
        }
        CamembertModel.openConnection()
        if let ret = camembert.getObjectsWithQuery(requestSelect!, table: table!) {
            return ret
        }
        return []
    }
    
    class func removeTable() {
        CamembertModel.openConnection()
        let table = getRawClassName()
        let requestRemove :String = "DROP TABLE IF EXISTS \(table!);"
        
        camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
            requestRemove.cStringUsingEncoding(NSUTF8StringEncoding)!)
    }
    
    override init() {
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