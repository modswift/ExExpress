//
//  Module.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension String {
  
  public func leftpad(_ length: Int, c: Character = " ") -> String {
    let oldLength = self.characters.count
    guard oldLength < length else { return self }
    
    let prefix = c._repeat(times: (length - oldLength))
    
    return prefix + self
  }
    
}

private extension Character {
  
  func _repeat(times t: Int) -> String {
    // This likely can be done faster. Maybe using a dynamic char sequence?
    // Given that this function is so important that it b0rked half the
    // Internet, it should be as fast ass possible.
    
    let s = Array<Character>(repeating: self, count: t)
    return String(s)
  }
  
}
