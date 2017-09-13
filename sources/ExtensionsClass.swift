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
        for index in 0..<number {
            resultArray.append(self[index])
        }
        return resultArray
    }
    
    func TakeRange(startIndex: Int, offset: Int) -> Array{
        var resultArray = Array()
        var m_offset = offset
        if m_offset > self.count {
            m_offset = self.count
        }
        for i in startIndex...m_offset {
            resultArray.append(self[i])
        }
        return resultArray
    }
    
    func FirstOrDefault() -> Element?{
        if self.count > 0 {
            return self[0]
        }else{
            return nil
        }
    }
    
    func LastOrDefault() -> Element?{
        if self.count > 0{
            return self[self.count - 1]
        }else{
            return nil
        }
    }
    
    func Union(arr: Array) -> Array{
        var resultArray = self
        for i in 0..<arr.count {
            resultArray.append(arr[i])
        }
        return resultArray
    }
    
}
