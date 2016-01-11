//
//  SwiftSQL.swift
//  SwiftSQL
//
//  Created by Remi Robert on 20/08/14.
//  Modified by Omar Bizreh on 11/1/16.
//  Copyright (c) 2014 remirobert. All rights reserved.
//
import Foundation
// Code from https://github.com/nerdyc/Squeal
#if os(iOS)
#if arch(i386) || arch(x86_64)
    import sqlite3_ios_simulator
    #else
    import sqlite3_ios
#endif
#else
    import sqlite3_osx
#endif
// End of code
    
@objc public class CamembertModel :NSObject {
    
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
        
        let mirror = Mirror(reflecting: self)
        let children = mirror.children
        let lastIndex = children.endIndex
        var requestPush = "INSERT INTO " + self.nameTable + " ("
        
        for i in children.indices
        {
            if (i.successor() == lastIndex)
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
                let dateformatter = NSDateFormatter();
                dateformatter.dateFormat = Camembert.Date_Time_Format;
                let date = (currentValue as! NSDate)
                _ = dateformatter.dateFromString("\(date)")
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
            
            if (i.successor() == lastIndex)
            {
                requestPush += ");"
            }
            else
            {
                requestPush += ", "
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
                let dateformatter = NSDateFormatter();
                dateformatter.dateFormat = Camembert.Date_Time_Format;
                let date = (currentValue as! NSDate)
                requestUpdate += "\(children[i].label!) = \"\(date)\""
                break;
                
            case _ where (currentValue as? BIT != nil):
                let result = (currentValue as! Bool) ? "1" : "0";
                requestUpdate += "\(children[i].label!) = \"\(result)\""
            default: requestUpdate += "\(children[i].label!) = \(currentValue)"
            }
            
            if (i.successor() == lastIndex)
            {
                requestUpdate += " WHERE id = \(self.id!);"
            }
            else
            {
                requestUpdate += ", "
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
        let requestDelete :String = "DELETE FROM \(self.nameTable) WHERE id=\(self.id!)"
        
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
    
    class func getNameTable(inout tmpNameTable :String) -> String {
        let parseString = "0123456789"
        
        for currentNumberParse in parseString.characters {
            var parseName = tmpNameTable.componentsSeparatedByString(String(currentNumberParse))
            if parseName.count > 0 {
                tmpNameTable = parseName[parseName.count - 1]
            }
        }
        return tmpNameTable
    }
    
    func _initNameTable() {
        CamembertModel.openConnection()
        
        var tmpNameTable = NSString(CString: object_getClassName(self), encoding: NSUTF8StringEncoding) as! String
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
//                let request :COpaquePointer = nil
                camembertExecSqlite3(UnsafeMutablePointer<Void>(DataAccess.access.dataAccess),
                    requestCreateTable.cStringUsingEncoding(NSUTF8StringEncoding)!)
            }
        }
        return true
    }
    
    class func numberElement() -> Int {
        CamembertModel.openConnection()
        
        var tmpNameTable = NSString(CString: class_getName(self), encoding: NSUTF8StringEncoding) as! String
        tmpNameTable = tmpNameTable.componentsSeparatedByString(".")[1]
        let requestNumberlement :String = "SELECT COUNT(*) FROM \(CamembertModel.getNameTable(&tmpNameTable));"
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
        
        let requestInit :String = "SELECT * FROM \(self.nameTable) WHERE id=\(id);"
        var ptrRequest :COpaquePointer = nil
        
        if sqlite3_prepare_v2(DataAccess.access.dataAccess,
            requestInit.cStringUsingEncoding(NSUTF8StringEncoding)!, -1, &ptrRequest, nil) != SQLITE_OK {
                sqlite3_finalize(ptrRequest);
                return Void()
        }
        
        if sqlite3_step(ptrRequest) == SQLITE_ROW
        {
            self.setId(Int(sqlite3_column_int(ptrRequest, 0)))
            for var index = 1; index < Int(sqlite3_column_count(ptrRequest)); index++ {
                let columName :String = NSString(CString: sqlite3_column_name(ptrRequest,
                    CInt(index)), encoding: NSUTF8StringEncoding)! as String
                
                switch sqlite3_column_type(ptrRequest, CInt(index)) {
                case SQLITE_INTEGER:
                    self.setValue((Int(sqlite3_column_int(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_FLOAT:
                    self.setValue((Float(sqlite3_column_double(ptrRequest,
                        CInt(index))) as AnyObject), forKey: columName)
                case SQLITE_TEXT:
                    let stringValue = String.fromCString(UnsafePointer<CChar>(sqlite3_column_text(ptrRequest, CInt(index))))
                    self.setValue(stringValue, forKey: columName)
                default: Void()
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