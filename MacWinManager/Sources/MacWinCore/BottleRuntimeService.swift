import Foundation

public enum BottleRuntimeAction: String, Codable, Equatable, Sendable {
    case cleanupOrphans
    case stopAll
    case restart
}

public struct BottleRuntimeReport: Codable, Equatable, Sendable {
    public var generatedAt: Date
    public var bottleId: String
    public var bottleName: String
    public var winePrefixPath: String
    public var entries: [RuntimeProcessEntry]

    public init(
        generatedAt: Date = Date(),
        bottleId: String,
        bottleName: String,
        winePrefixPath: String,
        entries: [RuntimeProcessEntry]
    ) {
        self.generatedAt = generatedAt
        self.bottleId = bottleId
        self.bottleName = bottleName
        self.winePrefixPath = winePrefixPath
        self.entries = entries
    }

    public var activeApplicationEntries: [RuntimeProcessEntry] {
        entries.filter { entry in
            !entry.isDetachedWineSystemProcess
                && !entry.isWineDeviceService
        }
    }

    public var detachedSystemEntries: [RuntimeProcessEntry] {
        entries.filter(\.isDetachedWineSystemProcess)
    }

    public var uninterruptibleEntries: [RuntimeProcessEntry] {
        entries.filter(\.isUninterruptible)
    }

    public var isIdle: Bool {
        activeApplicationEntries.isEmpty
    }
}

public struct BottleRuntimeActionResult: Codable, Equatable, Sendable {
    public var action: BottleRuntimeAction
    public var bottleId: String
    public var requestedProcessCount: Int
    public var stoppedProcessIdentifiers: [Int32]
    public var failedProcessIdentifiers: [Int32]
    public var wineServerExitCode: Int32?
    public var restarted: Bool
    public var remainingProcessCount: Int

    public init(
        action: BottleRuntimeAction,
        bottleId: String,
        requestedProcessCount: Int = 0,
        stoppedProcessIdentifiers: [Int32] = [],
        failedProcessIdentifiers: [Int32] = [],
        wineServerExitCode: Int32? = nil,
        restarted: Bool = false,
        remainingProcessCount: Int = 0
    ) {
        self.action = action
        self.bottleId = bottleId
        self.requestedProcessCount = requestedProcessCount
        self.stoppedProcessIdentifiers = stoppedProcessIdentifiers
        self.failedProcessIdentifiers = failedProcessIdentifiers
        self.wineServerExitCode = wineServerExitCode
        self.restarted = restarted
        self.remainingProcessCount = remainingProcessCount
    }

    public var stoppedCount: Int { stoppedProcessIdentifiers.count }
    public var failedCount: Int { failedProcessIdentifiers.count }
    public var succeeded: Bool { failedProcessIdentifiers.isEmpty && remainingProcessCount == 0 }
}

public struct BottleRuntimeService {
    public var paths: MacWinPaths
    public var auditService: RuntimeProcessAuditService
    public var terminator: RuntimeProcessTerminator
    public var runner: WineRunner
    public var bootstrapBottle: @Sendable (BottleManifest, EngineManifest) throws -> BottleManifest

    public init(
        paths: MacWinPaths = MacWinPaths(),
        auditService: RuntimeProcessAuditService = RuntimeProcessAuditService(),
        terminator: RuntimeProcessTerminator = RuntimeProcessTerminator(),
        runner: WineRunner? = nil,
        bootstrapBottle: (@Sendable (BottleManifest, EngineManifest) throws -> BottleManifest)? = nil
    ) {
        self.paths = paths
        self.auditService = auditService
        self.terminator = terminator
        let effectiveRunner = runner ?? WineRunner(paths: paths)
        self.runner = effectiveRunner
        self.bootstrapBottle = bootstrapBottle ?? { bottle, engine in
            try BottleService(paths: paths)
                .bootstrapWinePrefixIfNeeded(bottle: bottle, engine: engine, force: true)
        }
    }

    public func report(for bottle: BottleManifest, generatedAt: Date = Date()) -> BottleRuntimeReport {
        let prefixPath = paths.bottleDirectory(id: bottle.id).standardizedFileURL.path
        let entries = auditService.makeReport().entries(inWinePrefix: prefixPath)
        return BottleRuntimeReport(
            generatedAt: generatedAt,
            bottleId: bottle.id,
            bottleName: bottle.name,
            winePrefixPath: prefixPath,
            entries: entries
        )
    }

    /// Removes adopted Wine system processes only when no Windows application remains in this Bottle.
    @discardableResult
    public func cleanupOrphans(
        in bottle: BottleManifest,
        generatedAt: Date = Date()
    ) -> BottleRuntimeActionResult {
        let before = report(for: bottle, generatedAt: generatedAt)
        guard before.isIdle else {
            return result(action: .cleanupOrphans, bottle: bottle, before: before)
        }

        let candidates = before.detachedSystemEntries.filter { !$0.isUninterruptible }
        let termination = terminator.terminate(entries: candidates)
        let after = report(for: bottle)
        return BottleRuntimeActionResult(
            action: .cleanupOrphans,
            bottleId: bottle.id,
            requestedProcessCount: termination.requestedCount,
            stoppedProcessIdentifiers: termination.stoppedProcessIdentifiers,
            failedProcessIdentifiers: termination.failedProcessIdentifiers,
            remainingProcessCount: after.entries.count
        )
    }

    @discardableResult
    public func stopAll(
        in bottle: BottleManifest,
        engine: EngineManifest,
        generatedAt: Date = Date()
    ) throws -> BottleRuntimeActionResult {
        let before = report(for: bottle, generatedAt: generatedAt)
        let candidates = before.entries.filter { !$0.isUninterruptible }
        let termination = terminator.terminate(entries: candidates)
        var wineServerExitCode: Int32?
        if engine.wineserverPath.isEmpty == false {
            let wineServerResult = try runner.terminateBottle(
                bottle: bottle,
                engine: engine,
                logName: "\(bottle.id)-runtime-stop.log"
            )
            wineServerExitCode = wineServerResult.exitCode
        }

        let after = report(for: bottle)
        return BottleRuntimeActionResult(
            action: .stopAll,
            bottleId: bottle.id,
            requestedProcessCount: termination.requestedCount,
            stoppedProcessIdentifiers: termination.stoppedProcessIdentifiers,
            failedProcessIdentifiers: termination.failedProcessIdentifiers,
            wineServerExitCode: wineServerExitCode,
            remainingProcessCount: after.entries.count
        )
    }

    @discardableResult
    public func restart(
        bottle: BottleManifest,
        engine: EngineManifest,
        generatedAt: Date = Date()
    ) throws -> BottleRuntimeActionResult {
        let stopped = try stopAll(in: bottle, engine: engine, generatedAt: generatedAt)
        guard stopped.failedProcessIdentifiers.isEmpty, stopped.remainingProcessCount == 0 else {
            return BottleRuntimeActionResult(
                action: .restart,
                bottleId: bottle.id,
                requestedProcessCount: stopped.requestedProcessCount,
                stoppedProcessIdentifiers: stopped.stoppedProcessIdentifiers,
                failedProcessIdentifiers: stopped.failedProcessIdentifiers,
                wineServerExitCode: stopped.wineServerExitCode,
                remainingProcessCount: stopped.remainingProcessCount
            )
        }

        _ = try bootstrapBottle(bottle, engine)
        let after = report(for: bottle)
        return BottleRuntimeActionResult(
            action: .restart,
            bottleId: bottle.id,
            requestedProcessCount: stopped.requestedProcessCount,
            stoppedProcessIdentifiers: stopped.stoppedProcessIdentifiers,
            failedProcessIdentifiers: stopped.failedProcessIdentifiers,
            wineServerExitCode: stopped.wineServerExitCode,
            restarted: true,
            remainingProcessCount: after.entries.count
        )
    }

    private func result(
        action: BottleRuntimeAction,
        bottle: BottleManifest,
        before: BottleRuntimeReport
    ) -> BottleRuntimeActionResult {
        BottleRuntimeActionResult(
            action: action,
            bottleId: bottle.id,
            remainingProcessCount: before.entries.count
        )
    }
}
