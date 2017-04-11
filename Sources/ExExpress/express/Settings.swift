//
//  Settings.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public protocol SettingsHolder {
  
  func set(_ key: String, _ value: Any?)
  func get(_ key: String) -> Any?
  
}

public extension SettingsHolder {
  
  public func enable(_ key: String) {
    set(key, true)
  }
  public func disable(_ key: String) {
    set(key, false)
  }
  
  public subscript(setting key : String) -> Any? {
    get { return get(key)    }
    set { set(key, newValue) }
  }
  
  
  // MARK: - Trampoline
  
  public var settings : ExpressSettings { return ExpressSettings(holder: self) }
}

public struct ExpressSettings {
  
  let holder : SettingsHolder
  
  public var env : String {
    return holder.get("env") as? String ?? "development"
  }
  
  public var xPoweredBy : Bool {
    guard let v = holder.get("x-powered-by") else { return true }
    return boolValue(v)
  }
}


// MARK: - Helpers

fileprivate func boolValue(_ v : Any) -> Bool {
  // TODO: this should be some Foundation like thing
  if let b = v as? Bool   { return b      }
  if let b = v as? Int    { return b != 0 }
  if let s = v as? String {
    switch s.lowercased() {
      case "no", "false", "0", "disable": return false
      default: return true
    }
  }
  return true
}
