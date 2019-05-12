// swift-tools-version:4.2
//
//  Package.swift
//  ExExpress
//
//  Created by Helge Hess on 11.05.18.
//  Copyright © 2019 ZeeZide. All rights reserved.
//
import PackageDescription

let package = Package(
  name: "ExExpress",

  products: [
    .library(name: "ExExpress", targets: [ "ExExpress" ]),
  ],
  
  dependencies: [
    .package(url: "https://github.com/AlwaysRightInstitute/mustache.git",
             from: "0.5.9"),
    .package(url: "https://github.com/modswift/Freddy.git",
             from: "3.0.57")
  ],
	
  targets: [
    .target(name: "ExExpress", dependencies: [ "mustache", "Freddy" ])
  ]
)
