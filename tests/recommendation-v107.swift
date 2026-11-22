import Foundation

@main
struct Recommendation107Tests {
    static func main() {
        let anchor = MusicTrack(id: "anchor00001", title: "Future - Mask Off", artist: "Future", duration: 204)
        let favArtist = MusicTrack(id: "favartist001", title: "21 Savage - Bank Account", artist: "21 Savage", duration: 220)
        let sameA1 = MusicTrack(id: "sameartist01", title: "21 Savage - A", artist: "21 Savage", duration: 200)
        let sameA2 = MusicTrack(id: "sameartist02", title: "21 Savage - B", artist: "21 Savage", duration: 200)
        let sameA3 = MusicTrack(id: "sameartist03", title: "21 Savage - C", artist: "21 Savage", duration: 200)
        let metro = MusicTrack(id: "metro000001", title: "Metro Boomin - Song", artist: "Metro Boomin", duration: 200)
        let gunna = MusicTrack(id: "gunna000001", title: "Gunna - Song", artist: "Gunna", duration: 200)
        let engine = RecommendationEngine()
        let ranked = engine.rank([.init(track: sameA1, relevance: 150), .init(track: sameA2, relevance: 145),
                                  .init(track: sameA3, relevance: 140), .init(track: metro, relevance: 130),
                                  .init(track: gunna, relevance: 125)], near: anchor, excluding: [],
                                favorites: [favArtist], history: [:], exploration: 0.2)
        precondition(ranked.count == 5)
        let firstThreeArtists = ranked.prefix(3).map { MusicMetadata.normalized(MusicMetadata.identity(for: $0).artist) }
        precondition(firstThreeArtists.filter { $0.contains("21 savage") }.count <= 2,
                    "Radio diversification should stop one artist from dominating the top results")
        precondition(ranked.first != nil)

        var recent = ListeningRecord(track: metro)
        recent.plays = 5; recent.seconds = 1800; recent.lastPlayed = Date()
        let cooldown = engine.rank([.init(track: metro, relevance: 150), .init(track: gunna, relevance: 140)],
                                  near: anchor, excluding: [], favorites: [], history: [metro.id: recent], exploration: 0.3)
        precondition(cooldown.first?.id != metro.id, "Recently played artists/tracks receive cooldown suppression")
        // Neighborhood learning should carry listening signals across artists.
        let indieAnchor = MusicTrack(id: "indieanchor1", title: "Olly - Song", artist: "Olly", duration: 210)
        let future = MusicTrack(id: "futuretrack01", title: "Future - Song", artist: "Future", duration: 210)
        let billie = MusicTrack(id: "billietrack01", title: "Billie Eilish - Song", artist: "Billie Eilish", duration: 210)
        var metroHistory = ListeningRecord(track: metro)
        metroHistory.plays = 12; metroHistory.seconds = 7200; metroHistory.lastPlayed = Date().addingTimeInterval(-86400)
        var gunnaHistory = ListeningRecord(track: gunna)
        gunnaHistory.plays = 10; gunnaHistory.seconds = 6000; gunnaHistory.lastPlayed = Date().addingTimeInterval(-86400)
        let learned = engine.rank([.init(track: future, relevance: 100), .init(track: billie, relevance: 100)],
                                 near: indieAnchor, excluding: [], favorites: [],
                                 history: [metro.id: metroHistory, gunna.id: gunnaHistory], exploration: 0.3)
        precondition(learned.first?.artist == "Future", "Listening to a style should transfer affinity to other artists in that neighborhood")
        print("OK 1.0.7 recommendation: artist affinity, cooldown, diversity, and learned style")
    }
}
