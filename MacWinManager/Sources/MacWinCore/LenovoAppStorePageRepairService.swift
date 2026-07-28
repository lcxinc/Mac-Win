import Foundation

final class LenovoAppStorePageRepairService: @unchecked Sendable {
    static let repairExpression = #"""
    (() => {
      const store = window._reduxStore;
      if (!store) return "not-ready:store";
      const state = store.getState();
      const native = state && state.native;
      const recommend = state && state.recommend;
      if (!native) return "not-ready:native";
      if (!recommend) return "not-ready:recommend";
      if (native.commandLineReady !== true) {
        store.dispatch({ type: "SET_COMMAND_LINE_READY", ready: true });
        return "patched-command-line-ready";
      }
      const exploreEntry = state && state.exploreEntry;
      if (!exploreEntry) return "not-ready:explore-entry";
      if (exploreEntry.initialized !== true) {
        const commandLine = String(native.commandLine || "");
        if (/(^|\s)-c\s+/.test(commandLine)) return "not-ready:special-command-line";
        store.dispatch({
          type: "EXPLORE_ENTRY_INIT",
          payload: { commandLineMode: "none", entrySource: "cold_start" }
        });
        return "patched-explore-entry";
      }
      if (recommend.recoBanner && Array.isArray(recommend.recoBanner.data) && recommend.recoBanner.data.length) {
        return "already-renderable";
      }
      const cards = recommend.recoRecommend && recommend.recoRecommend.pageCardList;
      if (!Array.isArray(cards) || !cards.length) return "not-ready:cards";
      if (!recommend.recoBannerDataIsResponse) return "not-ready:banner-response";
      const entries = performance.getEntriesByType("resource")
        .filter(entry => entry.name.includes("/appstorecontents/page/top_contents"));
      if (!entries.length) return "not-ready:request";
      const requestURL = new URL(entries[entries.length - 1].name);
      const getBannerKey = Number(requestURL.searchParams.get("time"));
      if (!Number.isFinite(getBannerKey)) return "not-ready:key";
      store.dispatch({
        type: "RECO_TOP_CONTENTS_SUCCESS",
        payload: {
          status: 0,
          message: "MacWin empty-banner compatibility fallback",
          data: [cards[0]],
          getBannerKey,
          pageType: "soft"
        }
      });
      return "patched-empty-banner";
    })()
    """#

    private let port: Int
    private let timeout: TimeInterval
    private let logURL: URL
    private let session: URLSession
    private let deadline: Date

    init(port: Int, timeout: TimeInterval = 60, logURL: URL) {
        self.port = port
        self.timeout = timeout
        self.logURL = logURL
        let configuration = URLSessionConfiguration.ephemeral
        configuration.connectionProxyDictionary = [:]
        self.session = URLSession(configuration: configuration)
        self.deadline = Date().addingTimeInterval(timeout)
    }

    static func startIfNeeded(environment: [String: String], launchLogURL: URL) {
        guard environment["MACWIN_LENOVO_PAGE_REPAIR"] == "1" else { return }
        let port = Int(environment["MACWIN_LENOVO_DEBUG_PORT"] ?? "") ?? 9231
        let repairLogURL = launchLogURL.deletingPathExtension()
            .appendingPathExtension("lenovo-page-repair.log")
        let service = LenovoAppStorePageRepairService(port: port, logURL: repairLogURL)
        Thread.detachNewThread {
            service.run()
        }
    }

    private func run() {
        appendLog("starting port=\(port) timeout=\(Int(timeout))")
        var requestID = 1
        while Date() < deadline {
            guard let socketURL = pageSocketURL() else {
                Thread.sleep(forTimeInterval: 0.25)
                continue
            }
            let socket = session.webSocketTask(with: socketURL)
            socket.resume()
            while Date() < deadline {
                if let status = evaluate(Self.repairExpression, using: socket, id: requestID) {
                    appendLog(status)
                    if status == "patched-empty-banner" || status == "already-renderable" {
                        socket.cancel(with: .normalClosure, reason: nil)
                        session.invalidateAndCancel()
                        return
                    }
                }
                requestID += 1
                Thread.sleep(forTimeInterval: 0.35)
            }
            socket.cancel(with: .goingAway, reason: nil)
        }
        appendLog("timed-out")
        session.invalidateAndCancel()
    }

    private func pageSocketURL() -> URL? {
        guard let endpoint = URL(string: "http://127.0.0.1:\(port)/json/list"),
              let pages = loadJSON(endpoint) as? [[String: Any]] else { return nil }
        return pages.lazy
            .filter { $0["type"] as? String == "page" }
            .compactMap { ($0["webSocketDebuggerUrl"] as? String).flatMap(URL.init(string:)) }
            .first
    }

    private func loadJSON(_ url: URL) -> Any? {
        let semaphore = DispatchSemaphore(value: 0)
        let result = LockedValue<Any?>(nil)
        session.dataTask(with: url) { data, _, _ in
            if let data {
                result.value = try? JSONSerialization.jsonObject(with: data)
            }
            semaphore.signal()
        }.resume()
        guard semaphore.wait(timeout: .now() + 2) == .success else { return nil }
        return result.value
    }

    private func evaluate(_ expression: String, using task: URLSessionWebSocketTask, id: Int) -> String? {
        let payload: [String: Any] = [
            "id": id,
            "method": "Runtime.evaluate",
            "params": [
                "expression": expression,
                "returnByValue": true,
                "awaitPromise": true,
            ],
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: payload),
              let text = String(data: data, encoding: .utf8) else { return nil }

        let sendSemaphore = DispatchSemaphore(value: 0)
        let sendError = LockedValue<Error?>(nil)
        task.send(.string(text)) { error in
            sendError.value = error
            sendSemaphore.signal()
        }
        guard sendSemaphore.wait(timeout: .now() + 2) == .success,
              sendError.value == nil else { return nil }

        while Date() < deadline {
            let receiveSemaphore = DispatchSemaphore(value: 0)
            let received = LockedValue<URLSessionWebSocketTask.Message?>(nil)
            task.receive { result in
                if case let .success(message) = result {
                    received.value = message
                }
                receiveSemaphore.signal()
            }
            guard receiveSemaphore.wait(timeout: .now() + 2) == .success else { return nil }
            let responseText: String?
            switch received.value {
            case let .string(value): responseText = value
            case let .data(value): responseText = String(data: value, encoding: .utf8)
            case nil: responseText = nil
            @unknown default: responseText = nil
            }
            guard let responseText,
                  let responseData = responseText.data(using: .utf8),
                  let response = try? JSONSerialization.jsonObject(with: responseData) as? [String: Any],
                  response["id"] as? Int == id else { continue }
            let result = response["result"] as? [String: Any]
            let remoteResult = result?["result"] as? [String: Any]
            return remoteResult?["value"] as? String
        }
        return nil
    }

    private func appendLog(_ message: String) {
        let line = "\(ISO8601DateFormatter().string(from: Date())) \(message)\n"
        guard let data = line.data(using: .utf8) else { return }
        try? FileManager.default.createDirectory(
            at: logURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        if !FileManager.default.fileExists(atPath: logURL.path) {
            FileManager.default.createFile(atPath: logURL.path, contents: nil)
        }
        guard let handle = try? FileHandle(forWritingTo: logURL) else { return }
        defer { try? handle.close() }
        do {
            try handle.seekToEnd()
            try handle.write(contentsOf: data)
        } catch { }
    }
}

private final class LockedValue<Value>: @unchecked Sendable {
    private let lock = NSLock()
    private var storage: Value

    init(_ value: Value) {
        storage = value
    }

    var value: Value {
        get { lock.withLock { storage } }
        set { lock.withLock { storage = newValue } }
    }
}
