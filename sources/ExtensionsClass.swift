//
//  ArrayUtils.swift
//  SwiftUtilsLib
//
//  Created by Omar Bizreh on 2/15/15.
//  Copyright (c) 2015 Omar Bizreh. All rights reserved.
//

import Foundation

extension Array {
    func Take(number: Int) -> Array{
        var resultArray = Array()
        for (var i = 0; i < number; i++) {
            resultArray.append(self[i])
        }
        return resultArray
    }
    
    func TakeRange(startIndex: Int, offset: Int) -> Array{
        var resultArray = Array()
        var m_offset = offset
        if m_offset > self.count {
            m_offset = self.count
        }
        for (var i = startIndex; i <= m_offset; i++) {
            resultArray.append(self[i])
        }
        return resultArray
    }
    
    func FirstOrDefault() -> T?{
        if self.count > 0 {
            return self[0]
        }else{
            return nil
        }
    }
    
    func LastOrDefault() -> T?{
        if self.count > 0{
            return self[self.count - 1]
        }else{
            return nil
        }
    }
    
    func Union(arr: Array) -> Array{
        var resultArray = self
        for (var i = 0; i < arr.count; i++) {
            resultArray.append(arr[i])
        }
        return resultArray
    }
    
}