//
//  BKMeter.swift
//  Bankai
//
//  Created by Sergio Daniel Lozano on 5/26/16.
//  Copyright © 2016 Sergio Daniel L Garcia. All rights reserved.
//

import Foundation

public class BKMeter
{
    // MARK: - CLASS MEMBERS
    
    public static var meters: [String: BKMeter] = [String: BKMeter]()
    
    // MARK: - CLASS OPERATIONS
    
    public static func forProcess(process: String) -> BKMeter
    {
        if let meter = BKMeter.meters[process] {
            return meter
        } else {
            BKMeter.meters[process] = BKMeter(for: process)
            return BKMeter.meters[process]!
        }
    }
    
    // MARK: - INSTANCE OPERATIONS
    
    private var process: String
    
    private var startPoint: NSTimeInterval?
    
    private var stopPoints: [NSTimeInterval] = []
    private var stopReasons: [String] = []
    
    // MARK: - INITIALIZERS
    
    init(for process: String)
    {
        self.process = process
    }
    
    // MARK: - INSTANCE OPERATIONS
    
    public func start()
    {
        startPoint = NSDate().timeIntervalSince1970
        self.log("Start at: \(startPoint!) epoch time")
    }
    
    public func log(text: String)
    {
        print("[P: \(process)] >>> \(text)")
    }
    
    public func lap(for reason: String)
    {
        let nowPoint = NSDate().timeIntervalSince1970
        
        self.log("Lap at \(nowPoint) epoch time because \(reason.uppercaseString)")
        
        if (self.stopPoints.count > 0) {
            let lastStopIndex = self.stopPoints.count - 1
            self.log("=== \(self.seconds(from: self.stopPoints[lastStopIndex], to: nowPoint)) seconds since \(self.stopReasons[lastStopIndex].uppercaseString)")
        }
        
        self.log("=== \(self.seconds(from: self.startPoint!, to: nowPoint)) seconds since \(process.uppercaseString) started")
        
        self.addLap(for: reason, at: nowPoint)
    }
    
    private func addLap(for reason: String, at timestamp: NSTimeInterval)
    {
        self.stopPoints.append(timestamp)
        self.stopReasons.append(reason)
    }
    
    private func seconds(from point1: NSTimeInterval, to point2: NSTimeInterval) -> Double
    {
        return Double(point2) - Double(point1)
    }
    
    public func stop()
    {
        self.lap(for: "\(process.uppercaseString) finished")
        self.destroy()
    }
    
    public func fail()
    {
        self.lap(for: "\(process.uppercaseString) failed")
        self.destroy()
    }
    
    private func destroy()
    {
        self.stopPoints = [NSTimeInterval]()
        self.stopReasons = [String]()
        self.startPoint = nil
        
        self.log("\(self.process) process meter destroyed!")
        
        BKMeter.meters.removeValueForKey(self.process)
    }
    
    internal func printFullStack()
    {
        
    }
}