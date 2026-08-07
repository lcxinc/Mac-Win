import Foundation
import IOKit.pwr_mgt

final class ScreenAwakeController {
    private let mutex = NSLock()
    private var activeSessions = 0
    private var assertionIDs: [IOPMAssertionID] = []

    func beginSession(for reason: String) {
        mutex.lock()
        defer { mutex.unlock() }

        guard !reason.isEmpty else { return }
        if activeSessions > 0 {
            activeSessions += 1
            return
        }

        assertionIDs = createAssertions(reason: reason)
        if assertionIDs.isEmpty {
            return
        }

        activeSessions = 1
    }

    func endSession() {
        mutex.lock()
        defer { mutex.unlock() }

        guard activeSessions > 0 else { return }
        activeSessions -= 1
        if activeSessions > 0 { return }
        releaseAssertions()
    }

    deinit {
        mutex.lock()
        activeSessions = 0
        releaseAssertions()
        mutex.unlock()
    }

    private func createAssertions(reason: String) -> [IOPMAssertionID] {
        var ids: [IOPMAssertionID] = []

        for assertionType in [
            kIOPMAssertionTypeNoIdleSleep,
            kIOPMAssertionTypeNoDisplaySleep
        ] {
            var assertionID: IOPMAssertionID = 0
            let status = IOPMAssertionCreateWithName(
                assertionType as CFString,
                IOPMAssertionLevel(kIOPMAssertionLevelOn),
                reason as CFString,
                &assertionID
            )
            if status == kIOReturnSuccess {
                ids.append(assertionID)
            } else {
                for activeID in ids {
                    IOPMAssertionRelease(activeID)
                }
                return []
            }
        }

        return ids
    }

    private func releaseAssertions() {
        for assertionID in assertionIDs {
            IOPMAssertionRelease(assertionID)
        }
        assertionIDs.removeAll(keepingCapacity: true)
    }
}
