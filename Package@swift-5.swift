// swift-tools-version:5.0
//
//  Package.swift
//  ExExpress
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2019-2022 ZeeZide. All rights reserved.
//
import PackageDescription

let package = Package(
  name: "ExExpress",

  products: [
    .library(name: "ExExpress", targets: [ "ExExpress" ]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/AlwaysRightInstitute/mustache.git",
             from: "1.0.1"),
    .package(url: "https://github.com/modswift/Freddy.git",
             from: "3.0.58")
  ],
	
  targets: [
    .target(name: "ExExpress", dependencies: [ "mustache", "Freddy" ])
  ]
)
