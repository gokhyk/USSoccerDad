//
//  Player+LineUpBridge.swift
//  USSoccerDad
//
//  Created by Ayse Kula on 12/1/25.
//

import Foundation

extension Player {
    var seasonSnapshotForLineup: PlayerSeasonSnapshot {
        PlayerSeasonSnapshot(
            id: id,
            name: name,
            seasonMinutesPlayed: totalMinutesPlayed
        )
    }

    func availability(isAvailable: Bool) -> PlayerAvailability {
        PlayerAvailability(
            id: id,
            isAvailable: isAvailable
        )
    }
}

extension Array where Element == Player {
    func seasonSnapshotsForLineup() -> [PlayerSeasonSnapshot] {
        map { $0.seasonSnapshotForLineup }
    }

    func availabilityList(availableIds: Set<UUID>) -> [PlayerAvailability] {
        map { player in
            player.availability(isAvailable: availableIds.contains(player.id))
        }
    }
}
