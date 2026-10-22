import Testing
@testable import PruneIt

@MainActor
@Suite("WindowCloseQuitter quits only when the user closes PruneIt in on-demand mode")
struct WindowCloseQuitterTests {

    @Test("Closing the only window on demand quits")
    func userCloseOnDemandQuits() {
        #expect(
            WindowCloseQuitter.shouldQuit(
                showsMenuBarIcon: false,
                closedByPruneIt: false,
                closingIsOnScreenAppWindow: true,
                otherAppWindowOnScreen: false
            )
        )
    }

    @Test("In the menu bar mode, closing the window keeps PruneIt running")
    func menuBarModeKeepsRunning() {
        #expect(
            !WindowCloseQuitter.shouldQuit(
                showsMenuBarIcon: true,
                closedByPruneIt: false,
                closingIsOnScreenAppWindow: true,
                otherAppWindowOnScreen: false
            )
        )
    }

    /// The watcher-launch case: the suppressor closes the first window, and a
    /// review may be about to open a new one.
    @Test("A window PruneIt closes itself never quits")
    func pruneItCloseDoesNotQuit() {
        #expect(
            !WindowCloseQuitter.shouldQuit(
                showsMenuBarIcon: false,
                closedByPruneIt: true,
                closingIsOnScreenAppWindow: true,
                otherAppWindowOnScreen: false
            )
        )
    }

    @Test("Closing a sheet, panel, or already-closed window does not quit")
    func nonAppWindowDoesNotQuit() {
        #expect(
            !WindowCloseQuitter.shouldQuit(
                showsMenuBarIcon: false,
                closedByPruneIt: false,
                closingIsOnScreenAppWindow: false,
                otherAppWindowOnScreen: false
            )
        )
    }

    @Test("Closing one of two windows does not quit")
    func secondWindowKeepsRunning() {
        #expect(
            !WindowCloseQuitter.shouldQuit(
                showsMenuBarIcon: false,
                closedByPruneIt: false,
                closingIsOnScreenAppWindow: true,
                otherAppWindowOnScreen: true
            )
        )
    }
}
