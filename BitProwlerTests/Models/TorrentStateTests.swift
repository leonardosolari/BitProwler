import Testing
import SwiftUI
@testable import BitProwler

struct TorrentStateTests {
    
    @Test func initializationCaseInsensitivity() {
        #expect(TorrentState(from: "downloading") == .downloading)
        #expect(TorrentState(from: "DOWNLOADING") == .downloading)
        #expect(TorrentState(from: "DoWnLoAdInG") == .downloading)
        #expect(TorrentState(from: "unknown_state_string") == .unknown)
    }
    
    @Test func isPausedLogic() {
        let pausedStates: [TorrentState] = [.pausedDL, .pausedUP, .stoppedDL, .stoppedUP]
        
        for state in pausedStates {
            #expect(state.isPaused == true)
        }
        
        let activeStates: [TorrentState] = [.downloading, .uploading, .stalledDL, .metaDL, .forcedDL]
        
        for state in activeStates {
            #expect(state.isPaused == false)
        }
    }
    
    @Test func isForcedLogic() {
        #expect(TorrentState.forcedDL.isForced == true)
        #expect(TorrentState.forcedUP.isForced == true)
        
        #expect(TorrentState.downloading.isForced == false)
        #expect(TorrentState.pausedDL.isForced == false)
    }
    
    @Test func displayNameLocalization() {
        #expect(TorrentState.downloading.displayName == "Downloading")
        #expect(TorrentState.metaDL.displayName == "Downloading Metadata")
        #expect(TorrentState.error.displayName == "Error")
        #expect(TorrentState.unknown.displayName == "Unknown")
    }
}