//
//  HealthKitManager.swift
//  steps tracker Watch App
//
//  Created by Kushal on 24/10/25.
//

import Foundation
import HealthKit
import SwiftUI
import Combine

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()
    @Published var stepCount: Int = 0
    @Published var isAuthorized: Bool = false
    @Published var dailyGoal: Int = 10000
    
    init() {
        checkAuthorizationStatus()
    }
    
    func requestAuthorization() {
        guard HKHealthStore.isHealthDataAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        healthStore.requestAuthorization(toShare: nil, read: [stepType]) { [weak self] success, error in
            DispatchQueue.main.async {
                self?.isAuthorized = success
                if success {
                    self?.fetchStepCount()
                    self?.startObservingSteps()
                } else {
                    print("HealthKit authorization failed: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
    }
    
    private func checkAuthorizationStatus() {
        guard HKHealthStore.isHealthDataAvailable() else { return }
        
        let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let status = healthStore.authorizationStatus(for: stepType)
        
        DispatchQueue.main.async {
            self.isAuthorized = (status == .sharingAuthorized)
            if self.isAuthorized {
                self.fetchStepCount()
                self.startObservingSteps()
            }
        }
    }
    
    func fetchStepCount() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let calendar = Calendar.current
        let now = Date()
        let startOfDay = calendar.startOfDay(for: now)
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictStartDate)
        
        let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { [weak self] _, result, error in
            DispatchQueue.main.async {
                if let result = result,
                   let sum = result.sumQuantity() {
                    self?.stepCount = Int(sum.doubleValue(for: HKUnit.count()))
                } else {
                    print("Error fetching step count: \(error?.localizedDescription ?? "Unknown error")")
                }
            }
        }
        
        healthStore.execute(query)
    }
    
    private func startObservingSteps() {
        guard let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount) else { return }
        
        let observerQuery = HKObserverQuery(sampleType: stepType, predicate: nil) { [weak self] _, _, error in
            if let error = error {
                print("Observer query error: \(error.localizedDescription)")
                return
            }
            
            DispatchQueue.main.async {
                self?.fetchStepCount()
            }
        }
        
        healthStore.execute(observerQuery)
    }
    
    func setDailyGoal(_ goal: Int) {
        dailyGoal = goal
    }
}
