//
//  UU7GameViewModel.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 2/6/26.
//

import Foundation




@MainActor
final class UU7GameViewModel: ObservableObject {
    @Published var gameState: GameState?
    @Published var RunPhase: RunPhase?
    
    @Published var gameClockSeconds: Int = 0
    
    
    
    
    func tickOneSecond() {
       
        
        guard var state = gameState else { return }
        guard state.status == .normalGame || state.status == .noSubGame else { return }
        
        //increase gameClock
        gameClockSeconds += 1
        
        let quarterDurationSeconds = state.config.minutesPerPeriod * 60
        
        
        //if gameClockSeconds is more than duration, period is ended, moved to next
        if gameClockSeconds > quarterDurationSeconds {
            //RunPhase = moveToNextPhase()
            
        }
        
        //Update Players Playing Time
        
        
        //Check if there will be a sub in 60 seconds
        //if there will be a sub, prepare sub list
        //turn on the pendingsubstitution
        
        
        gameState = state
    }
    
    
    
    
    
    
    
    
    
}
