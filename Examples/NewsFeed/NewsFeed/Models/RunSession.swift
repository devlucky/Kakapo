//
//  RunSession.swift
//  NewsFeed
//
//  Created by Alex Manzella on 26/06/16.
//  Copyright © 2016 devlucky. All rights reserved.
//

import Foundation
import Kakapo

struct RunSession: JSONAPIEntity {
    
    struct TrailingPlanState {
        let day: Int
        let daysPerWeek: Int
        let level: Int
        let trainingPlanId: String
        let trainingPlanStatusId: String
        let trainingPlanType: String
        let trainingPlanVersion: PropertyPolicy<String> // not sure if it's a string
        let week: Int
    }
    
    struct Exercise {
        let currentRound: Int
        let duration: Int
        let exerciseId: String
        let exerciseType: String
        let indexInRound: Int
        let repetitions: Int
        let startedAt: Int64
        let targetDuration: PropertyPolicy<Int>
        let targetRepetitions: Int
    }
    
    let id: String
    let averageSpeed: Float
    let calories: Int
    let createdAt: Int64
    let updatedAt: Int64
    let currentTrailingPlanState: PropertyPolicy<TrailingPlanState>
    let distance: Float
    let duration: Int
    let elevationGain: Float
    let elevationLoss: Float
    let encodedTrace: String
    let endTime: Int64
    let legacyId: Int64
    let maxSpeed: Float
    let notes: String
    let pauseDuration: Int
    let sportTypeId: String
    let startTime: Int64
    let subjectiveIntensity: Int
    let workoutData: PropertyPolicy<[Exercise]>
    let creationApplication: CreationApplication
    let sportType: SportType
    let user: User
}
