//
//  SubstitutionIntensity.swift
//  USSoccerDad
//
//  Created by Claude on 2/9/26.
//

import Foundation

enum SubstitutionIntensity: String, CaseIterable, Identifiable, Codable {
    case frequent = "Frequent"
    case balanced = "Balanced"
    case infrequent = "Infrequent"
    
    var id: String { rawValue }
    
    /// Calculate substitution times in seconds for a given period duration and age group
    /// - Parameters:
    ///   - periodSeconds: Duration of the period in seconds
    ///   - ageGroup: The age group (U5-U17)
    /// - Returns: Array of substitution times in seconds, filtered to exclude subs within 90 seconds of period end
    func substitutionTimes(periodSeconds: Int, ageGroup: AgeGroup) -> [Int] {
        let isYoungerGroup = [.u5, .u6, .u7].contains(ageGroup)
        
        let rawTimes: [Int]
        
        switch self {
        case .frequent:
            if isYoungerGroup {
                // U5-U7: 3 subs per period
                rawTimes = [
                    periodSeconds / 4,
                    periodSeconds / 2,
                    (periodSeconds * 3) / 4
                ]
            } else {
                // U8+: 4 subs per period
                rawTimes = [
                    periodSeconds / 5,
                    (periodSeconds * 2) / 5,
                    (periodSeconds * 3) / 5,
                    (periodSeconds * 4) / 5
                ]
            }
            
        case .balanced:
            if isYoungerGroup {
                // U5-U7: 2 subs per period
                rawTimes = [
                    periodSeconds / 3,
                    (periodSeconds * 2) / 3
                ]
            } else {
                // U8+: 3 subs per period
                rawTimes = [
                    periodSeconds / 4,
                    periodSeconds / 2,
                    (periodSeconds * 3) / 4
                ]
            }
            
        case .infrequent:
            if isYoungerGroup {
                // U5-U7: 1 sub per period
                rawTimes = [periodSeconds / 2]
            } else {
                // U8+: 2 subs per period
                rawTimes = [
                    periodSeconds / 3,
                    (periodSeconds * 2) / 3
                ]
            }
        }
        
        // Filter out any subs within 90 seconds (1.5 minutes) of period end
        let minimumTimeBeforeEnd = 90
        return rawTimes.filter { $0 <= periodSeconds - minimumTimeBeforeEnd }
    }
    
    /// Human-readable description of substitution frequency
    var description: String {
        switch self {
        case .frequent:
            return "More frequent substitutions (3-4 per period)"
        case .balanced:
            return "Balanced substitutions (2-3 per period)"
        case .infrequent:
            return "Less frequent substitutions (1-2 per period)"
        }
    }
}
