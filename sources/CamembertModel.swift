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
    
    func setId(_ id :Int) {
        self.id = id
    }
    
    private class func openConnection() {
        let _ = Camembert.closeDataBase()
        if let dbFolder = DataAccess.access.DbPath {
            let _ = Camembert.initDataBase(dbFolder,
                                           nameDatabase: DataAccess.access.nameDataBase!)
        }else{
            let _ = Camembert.initDataBase(DataAccess.access.nameDataBase!)
        }
    }
    
    enum OperationResult{
        case Success,
        Error_DuplicatedID,
        Error_NoRecordFoundWithID,
        Error_GeneralFailure
    }
    
    func push() -> OperationResult{
        if self.id != nil {
            return OperationResult.Error_DuplicatedID;
        }
        let _ = self.createTable()
        CamembertModel.openConnection()
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        let lastIndex = children.endIndex
        var requestPush = "INSERT INTO " + self.nameTable + " ("
        
        for i in children.indices
        {
            if (i == lastIndex)
            {
                requestPush += children[i].label! + ")"
            }
            else
            {
                requestPush += children[i].label! + ", "
            }
        }
        
        requestPush += " VALUES ("
        
        for i in children.indices
        {
            let currentValue = children[i].value
            
            switch currentValue
            {
            case _ where (currentValue as? TEXT != nil): requestPush += "\"\(currentValue)\""
            case _ where (currentValue as? DATE_TIME != nil):
                let dateformatter = DateFormatter();
                dateformatter.dateFormat = Camembert.Date_Time_Format;
                let date = (currentValue as! NSDate)
                _ = dateformatter.date(from: "\(date)")
                requestPush += "\"\(date)\""
                break;
            case _ where (currentValue as? BIT != nil):
                if (currentValue as! Bool)
                {
                    requestPush += "1";
                }
                else
                {
                    requestPush += "0";
                }
                break;
            default: requestPush += "\(currentValue)"
            }
            
            if (i == lastIndex)
            {
                requestPush += ");"
            }
            else
            {
                requestPush += ", "
            }
        }
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestPush.cString(using: String.Encoding.utf8)!)
        self.id = Int(sqlite3_last_insert_rowid(DataAccess.access.dataAccess))
        var opResult: OperationResult = OperationResult.Success
        if !result{
            opResult = OperationResult.Error_GeneralFailure
        }
        return opResult
    }
    
    func update() -> OperationResult
    {
        if self.id == -1
        {
            return OperationResult.Error_NoRecordFoundWithID
        }
        CamembertModel.openConnection()
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children // .dropFirst()
        let lastIndex = children.endIndex
        
        var requestUpdate :String = "UPDATE \(self.nameTable) SET "
        for i in children.indices
        {
            let currentValue = children[i].value
            
            switch currentValue
            {
            case _ where (currentValue as? TEXT != nil): requestUpdate += "\(children[i].label!) = \"\(currentValue)\""
            case _ where (currentValue as? DATE_TIME != nil):
                let dateformatter = DateFormatter();
                dateformatter.dateFormat = Camembert.Date_Time_Format;
                let date = (currentValue as! NSDate)
                requestUpdate += "\(children[i].label!) = \"\(date)\""
                break;
                
            case _ where (currentValue as? BIT != nil):
                let result = (currentValue as! Bool) ? "1" : "0";
                requestUpdate += "\(children[i].label!) = \"\(result)\""
            default: requestUpdate += "\(children[i].label!) = \(currentValue)"
            }
            
            if (i == lastIndex)
            {
                requestUpdate += " WHERE id = \(self.id!);"
            }
            else
            {
                requestUpdate += ", "
            }
        }
        
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestUpdate.cString(using: String.Encoding.utf8)!)
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
        let requestDelete :String = "DELETE FROM \(self.nameTable) WHERE id=\(self.id!)"
        
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestDelete.cString(using: String.Encoding.utf8)!)
        self.id = -1
        if !result{
            return OperationResult.Error_GeneralFailure
        }
        return OperationResult.Success
    }
    
    func getSchemaTable() -> [String]! {
        CamembertModel.openConnection()
        
        var arrayString :[String] = []
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children // .dropFirst()
        
        for i in children.indices
        {
            let currentValue = children[i].value
            
            switch currentValue
            {
            case _ where (currentValue as? INTEGER != nil):
                arrayString.append("\(children[i].label!) INTEGER")
            case _ where (currentValue as? REAL != nil):
                arrayString.append("\(children[i].label!) REAL")
            case _ where (currentValue as? TEXT != nil):
                arrayString.append("\(children[i].label!) TEXT")
            case _ where (currentValue as? DATE_TIME != nil):
                arrayString.append("\(children[i].label!) TEXT")
            case _ where (currentValue as? BIT != nil):
                arrayString.append("\(children[i].label!) INTEGER")
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
    
    class func getNameTable(_ tmpNameTable :inout String) -> String {
        let parseString = "0123456789"
        
        for currentNumberParse in parseString.characters {
            var parseName = tmpNameTable.components(separatedBy: String(currentNumberParse))
            if parseName.count > 0 {
                tmpNameTable = parseName[parseName.count - 1]
            }
        }
        return tmpNameTable
    }
    
    func _initNameTable() {
        CamembertModel.openConnection()
        
        var tmpNameTable = String(cString: object_getClassName(self),
                                  encoding: String.Encoding.utf8)
        self.nameTable = CamembertModel.getNameTable(&tmpNameTable!).components(separatedBy: ".")[1]
    }
    
    func sendRequest(ptrRequest :inout OpaquePointer?, request :String) -> Bool {
        CamembertModel.openConnection()
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              request.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
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
                for index in 0 ..< configurationTable.count {
                    switch index {
                    case configurationTable.count - 1: requestCreateTable += configurationTable[index]
                    default: requestCreateTable += configurationTable[index] + ", "
                    }
                }
                requestCreateTable += ");"
                camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                     requestCreateTable.cString(using: String.Encoding.utf8)!)
            }
        }
        return true
    }
    
    class func numberElement() -> Int {
        CamembertModel.openConnection()
        
        var tmpNameTable = String(cString: class_getName(self),
                                  encoding: String.Encoding.utf8)!
        tmpNameTable = tmpNameTable.components(separatedBy:".")[1]
        let requestNumberlement :String = "SELECT COUNT(*) FROM \(CamembertModel.getNameTable(&tmpNameTable));"
        var ptrRequest :OpaquePointer? = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              requestNumberlement.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
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
    
    func _initWithId(_ id :Int) {
        CamembertModel.openConnection()
        
        let requestInit :String = "SELECT * FROM \(self.nameTable) WHERE id=\(id);"
        var ptrRequest :OpaquePointer? = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
                              requestInit.cString(using: String.Encoding.utf8)!,
                              -1,
                              &ptrRequest,
                              nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return Void()
        }
        
        if sqlite3_step(ptrRequest) == SQLITE_ROW
        {
            self.setId(Int(sqlite3_column_int(ptrRequest, 0)))
            for index in 1 ..< Int(sqlite3_column_count(ptrRequest)) {
                let columName :String = String(cString: sqlite3_column_name(ptrRequest, CInt(index))!,
                                               encoding: String.Encoding.utf8)!
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    self.setValue((Int(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_FLOAT:
                    self.setValue((Float(sqlite3_column_double(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_TEXT:
                    let stringValue = String(cString:sqlite3_column_text(ptrRequest, CInt(index)))
                    self.setValue(stringValue, forKey: columName)
                default: Void()
                }
            }
        }
        sqlite3_finalize(ptrRequest);
    }
    
    class func getRawClassName() -> String? {
        let name = NSStringFromClass(self)
        let components = name.components(separatedBy:".")
        return components.last
    }
    
    class func select(selectRequest select: Select) -> [AnyObject]? {
        let camembert = Camembert()
        let table = getRawClassName()
        var requestSelect: String? = nil
        var m_OrderBy = "1";
        
        switch select {
        case .SelectAll(let OrderOperator, let OrderBy):
            var op: String;
            if !OrderBy.isEmpty {
                m_OrderBy = OrderBy
            }
            switch OrderOperator{
            case .Ascending:
                op = "asc"
            default:
                op = "desc"
            }
            requestSelect = "SELECT * FROM \(table!) ORDER BY \(m_OrderBy) \(op)"
        case .Limit(let value, let OrderOperator, let OrderBy):
            var op: String;
            if !OrderBy.isEmpty {
                m_OrderBy = OrderBy
            }
            switch OrderOperator{
            case .Ascending:
                op = "asc"
            default:
                op = "desc"
            }
            requestSelect = "SELECT * FROM \(table!) LIMIT \(value) ORDER BY \(m_OrderBy) \(op)"
        case .Between(let startValue, let endValue, let OrderOperator, let OrderBy):
            var op: String;
            if !OrderBy.isEmpty {
                m_OrderBy = OrderBy
            }
            switch OrderOperator{
            case .Ascending:
                op = "asc"
            default:
                op = "desc"
            }
            requestSelect = "SELECT * FROM \(table!) WHERE ID BETWEEN \(startValue) AND \(endValue) ORDER BY \(m_OrderBy) \(op)"
        case .CustomRequest(let request):
            requestSelect = request
        case .Where(let Field, let Operator, let value, let OrderOperator, let OrderBy):
            var op: String;
            if !OrderBy.isEmpty {
                m_OrderBy = OrderBy
            }
            switch OrderOperator{
            case .Ascending:
                op = "asc"
            default:
                op = "desc"
            }
            switch Operator{
            case .EqualsTo:
                var resultValue = String();
                
                if let _ = value as? BIT{
                    return nil
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) = \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .IsNull:
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) IS NULL"
                break;
            case .LargerOrEqual:
                var resultValue = String();
                if let _ = value as? BIT{
                    return nil
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) >= \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .LargerThan:
                var resultValue = String();
                if let _ = value as? BIT{
                    return nil
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) > \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .NotNull:
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) IS NOT NULL ORDER BY \(m_OrderBy) \(op)"
            case .SmallerOrEqual:
                var resultValue = String();
                if let _ = value as? BIT{
                    return nil
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) <= \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .SmallerThan:
                var resultValue = String();
                if let _ = value as? BIT{
                    return nil
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) < \(resultValue) ORDER BY \(m_OrderBy) \(op)"
//            case .IsNull:
//                requestSelect = "SELECT * FROM \(table!) WHERE \(Field) IS NULL ORDER BY \(m_OrderBy) \(op)"
            }
            break;
        }
        CamembertModel.openConnection()
        if let ret = camembert.getObjectsWithQuery(requestSelect!, table: table!) {
            return ret
        }
        return nil
    }
    
    class func removeTable() {
        CamembertModel.openConnection()
        let table = getRawClassName()
        let requestRemove :String = "DROP TABLE IF EXISTS \(table!);"
        
        camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                             requestRemove.cString(using: String.Encoding.utf8)!)
    }
    
    override init() {
        super.init()
        self._initNameTable()
    }
    
    init(id :Int) {
        super.init()
        self._initNameTable()
        self._initWithId(id)
    }
}

