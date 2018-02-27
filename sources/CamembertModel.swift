//
//  SwiftSQL.swift
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Copyright (c) 2014 remirobert. All rights reserved.
//

import Foundation

@objcMembers
class CamembertModel :NSObject {
    
    private var nameTable = ""
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
        if id != nil {
            return OperationResult.Error_DuplicatedID;
        }
        let _ = createTable()
        CamembertModel.openConnection()
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        var requestPush = "INSERT INTO " + nameTable + " ("
        
        requestPush += children.map({ (child) -> String in
            child.label ?? ""
        })
            .joined(separator: ", ")
        
        requestPush += ") VALUES ("
        
        requestPush += children.map({ (child) -> String in
            var currentValue = child.value
            var result = ""
            switch currentValue = child.value {
            case _ where (currentValue as? TEXT != nil): result = "\"\(currentValue)\""
            case _ where (currentValue as? DATE_TIME != nil):
                let date = (currentValue as! Date)
                result = "\"\(date.timeIntervalSince1970)\""
                break;
            case _ where (currentValue as? BIT != nil):
                if (currentValue as! Bool)
                {
                    result = "1";
                }
                else
                {
                    result = "0";
                }
                break;
            default: result = "\(currentValue)"
            }
            
            return result
        })
            .joined(separator: ", ")
        
        requestPush += ");"
        
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestPush.cString(using: String.Encoding.utf8)!)
        id = Int(sqlite3_last_insert_rowid(DataAccess.access.dataAccess))
        var opResult: OperationResult = OperationResult.Success
        if !result{
            opResult = OperationResult.Error_GeneralFailure
        }
        return opResult
    }
    
    func update() -> OperationResult
    {
        if id == -1
        {
            return OperationResult.Error_NoRecordFoundWithID
        }
        CamembertModel.openConnection()
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children // .dropFirst()
        
        var requestUpdate :String = "UPDATE \(nameTable) SET "
        requestUpdate += children.map { (child) -> String in
            let currentValue = child.value
            
            switch currentValue {
            case _ where (currentValue as? TEXT != nil):
                return "\(child.label!) = \"\(currentValue)\""
            case _ where (currentValue as? DATE_TIME != nil):
                let date = (currentValue as! Date)
                return "\(child.label!) = \"\(date.timeIntervalSince1970)\""
                
            case _ where (currentValue as? BIT != nil):
                let result = (currentValue as! Bool) ? "1" : "0";
                return "\(child.label!) = \"\(result)\""
            default:
                return "\(child.label!) = \(currentValue)"
            }
            }
            .joined(separator: ", ")
        
        requestUpdate += " WHERE id = \(id!);"
        
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestUpdate.cString(using: String.Encoding.utf8)!)
        var opResult = OperationResult.Success
        if !result{
            opResult = OperationResult.Error_GeneralFailure
        }
        return opResult;
    }
    
    func remove() -> OperationResult{
        if id == nil {
            return OperationResult.Error_NoRecordFoundWithID;
        }
        CamembertModel.openConnection()
        let requestDelete :String = "DELETE FROM " + nameTable + " WHERE id=\(id!)"
        
        let result = camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                                          requestDelete.cString(using: String.Encoding.utf8)!)
        id = -1
        if !result{
            return OperationResult.Error_GeneralFailure
        }
        return OperationResult.Success
    }
    
    func getSchemaTable() -> [String]! {
        CamembertModel.openConnection()
        
        var arrayString :[String] = []
        
        let children = Mirror(reflecting: self).children
        
        for child in children
        {
            let currentValue = child.value
            let currentKey = child.label!
            switch currentValue
            {
            case _ where (currentValue as? TEXT != nil):
                arrayString.append(currentKey + " TEXT")
            case _ where (currentValue as? REAL != nil):
                arrayString.append(currentKey + " REAL")
            case _ where (currentValue as? INTEGER != nil):
                arrayString.append(currentKey + " INTEGER")
            case _ where (currentValue as? DATE_TIME != nil):
                arrayString.append(currentKey + " REAL")
            case _ where (currentValue as? BIT != nil):
                arrayString.append(currentKey + " INTEGER")
            default: return nil
            }
        }
        
        return arrayString
    }
    
    func isDate(_ key: String) -> Bool {
        let children = Mirror(reflecting: self).children
        
        for child in children.filter({ (child) -> Bool in
            guard let label = child.label else { return false }
            return label == key
        })
        {
            let currentValue = child.value
            switch currentValue
            {
            case _ where (currentValue as? DATE_TIME != nil):
                return true
            default: return false
            }
        }
        return false
    }
    
    func isTableExist() -> Bool {
        CamembertModel.openConnection()
        
        for currentTable in Camembert.getListTable() {
            if currentTable == nameTable {
                return true
            }
        }
        return false
    }
    
    class func getNameTable(_ tmpNameTable :inout String) -> String {
        let parseString = "0123456789"
        
        for currentNumberParse in parseString {
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
                                  encoding: String.Encoding.utf8)!
        tmpNameTable = tmpNameTable.components(separatedBy:".")[1]
        nameTable = CamembertModel.getNameTable(&tmpNameTable)
    }
    
    func sendRequest(ptrRequest :inout OpaquePointer?,
                     request :String) -> Bool {
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
        
        if isTableExist() == false {
            var requestCreateTable :String = "CREATE TABLE \(nameTable) (id INTEGER PRIMARY KEY AUTOINCREMENT, "
            if let configurationTable = getSchemaTable() {
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
        let requestNumberlement :String = "SELECT COUNT(*) FROM " + CamembertModel.getNameTable(&tmpNameTable) + ";"
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
        
        let requestInit :String = "SELECT * FROM \(nameTable) WHERE id=\(id);"
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
            setId(Int(sqlite3_column_int(ptrRequest, 0)))
            for index in 1 ..< Int(sqlite3_column_count(ptrRequest)) {
                let columName :String = String(cString: sqlite3_column_name(ptrRequest, CInt(index))!,
                                               encoding: String.Encoding.utf8)!
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    setValue((Int(sqlite3_column_int(ptrRequest,
                                                          CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_FLOAT:
                    if isDate(columName) {
                        setValue(Date(timeIntervalSince1970: TimeInterval(sqlite3_column_double(ptrRequest,
                                                                                                     CInt(index)))),
                                      forKey: columName)
                    } else {
                        setValue((Float(sqlite3_column_double(ptrRequest,
                                                                   CInt(index))) as AnyObject),
                                      forKey: columName)
                    }
                case SQLITE_TEXT:
                    let stringValue = String(cString:sqlite3_column_text(ptrRequest, CInt(index)))
                    setValue(stringValue, forKey: columName)
                default: Void()
                }
            }
        }
        sqlite3_finalize(ptrRequest);
    }
    
    class func getRawClassName() -> String {
        let name = NSStringFromClass(self)
        let components = name.components(separatedBy:".")
        return components.last ?? ""
    }
    
    class func select<T: CamembertModel>(selectRequest select: Select) -> [T] {
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
            requestSelect = "SELECT * FROM \(table) ORDER BY \(m_OrderBy) \(op)"
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
            requestSelect = "SELECT * FROM \(table) LIMIT \(value) ORDER BY \(m_OrderBy) \(op)"
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
            requestSelect = "SELECT * FROM \(table) WHERE ID BETWEEN \(startValue) AND \(endValue) ORDER BY \(m_OrderBy) \(op)"
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
                
                if let value = value as? BIT{
                    resultValue = value ? "1" : "0";
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x.timeIntervalSince1970)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) = \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .IsNull:
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) IS NULL"
                break;
            case .LargerOrEqual:
                var resultValue = String();
                if let _ = value as? BIT{
                    resultValue = (value as! Bool) ? "1" : "0";
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x.timeIntervalSince1970)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) >= \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .LargerThan:
                var resultValue = String();
                if let _ = value as? BIT{
                    resultValue = (value as! Bool) ? "1" : "0";
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x.timeIntervalSince1970)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) > \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .NotNull:
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) IS NOT NULL ORDER BY \(m_OrderBy) \(op)"
            case .SmallerOrEqual:
                var resultValue = String();
                if let _ = value as? BIT{
                    resultValue = (value as! Bool) ? "1" : "0";
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x.timeIntervalSince1970)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) <= \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            case .SmallerThan:
                var resultValue = String();
                if let _ = value as? BIT{
                    resultValue = (value as! Bool) ? "1" : "0";
                }else if let x = value as? TEXT {
                    resultValue = "\"\(x)\""
                }else if let x = value as? DATE_TIME{
                    resultValue = "\"\(x.timeIntervalSince1970)\""
                }else{
                    resultValue = "\(value)";
                }
                requestSelect = "SELECT * FROM \(table) WHERE \(Field) < \(resultValue) ORDER BY \(m_OrderBy) \(op)"
            }
            break;
        }
        CamembertModel.openConnection()
        return camembert.getObjectsWithQuery(requestSelect!, table: table) as [T]
    }
    
    class func removeTable() {
        CamembertModel.openConnection()
        let table = getRawClassName()
        let requestRemove :String = "DROP TABLE IF EXISTS \(table);"
        
        camembertExecSqlite3(UnsafeMutableRawPointer(DataAccess.access.dataAccess),
                             requestRemove.cString(using: String.Encoding.utf8)!)
    }
    
    override init() {
        super.init()
        _initNameTable()
    }
    
    init(id :Int) {
        super.init()
        _initNameTable()
        _initWithId(id)
    }
}
