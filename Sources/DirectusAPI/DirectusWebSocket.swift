//
//  DirectusWebSocket.swift
//  DirectusAPI
//
//  Created by Cedric Pugnaire on 26/05/2025.
//

import Foundation

@MainActor
public class DirectusWebSocket {
    private var apiManager: DirectusApiManagerProtocol
    private var webSocketTask: URLSessionWebSocketTask?
    private let urlSession: URLSession
    private(set) var subscriptionDataList: [any AnyDirectusWebSocketSubscription] = []

    public var onError: ((Error) -> Void)?
    public var onDone: (() -> Void)?

    public init(
        apiManager: DirectusApiManager,
        subscriptionDataList: [any AnyDirectusWebSocketSubscription],
        onError: ((Error) -> Void)? = nil,
        onDone: (() -> Void)? = nil
    ) {
        self.apiManager = apiManager
        self.subscriptionDataList = subscriptionDataList
        self.onError = onError
        self.onDone = onDone
        self.urlSession = URLSession(configuration: .default)

        connect()
    }

    private func connect() {
        guard let url = URL(string: apiManager.webSocketBaseUrl) else { return }

        webSocketTask = urlSession.webSocketTask(with: url)
        webSocketTask?.resume()
        receiveMessages()

        Task {
            if let token = apiManager.accessToken {
                try? await authenticate(accessToken: token)
            } else {
                subscribe()
            }
        }
    }

    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }

            switch result {
            case .failure(let error):
                Task { @MainActor in
                    self.onError?(error)
                }

            case .success(let message):
                switch message {
                case .string(let text):
                    Task { await self.handleMessage(text) }
                default:
                    break
                }
                Task { @MainActor in
                    self.receiveMessages() // continue listening
                }
            }
        }
    }

    private func handleMessage(_ message: String) async {
        guard let data = message.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else {
            return
        }

        switch type {
        case "ping":
            send(message: ["type": "pong"])

        case "auth":
            if let status = json["status"] as? String, status == "error",
               let error = (json["error"] as? [String: Any])?["code"] as? String,
               error == "TOKEN_EXPIRED" {
                sendRefreshToken()
            } else if let okStatus = json["status"] as? String, okStatus == "ok" {
                if let refresh = json["refresh_token"] as? String {
                    apiManager.refreshToken = refresh
                } else {
                    subscribe()
                }
            }

        case "subscription":
            guard let uid = json["uid"] as? String,
                  let event = json["event"] as? String else { return }

            guard let subscription = subscriptionDataList.first(where: { $0.uid == uid }) else {
                print("No subscription found for uid \(uid)")
                return
            }

            switch event {
            case "init", "create":
                subscription.onCreate?(json)
            case "update":
                subscription.onUpdate?(json)
            case "delete":
                subscription.onDelete?(json)
            case "unsubscribe":
                subscriptionDataList.removeAll { $0.uid == uid }
            default:
                break
            }

        default:
            break
        }
    }

    private func send(message: [String: Any]) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: jsonData, encoding: .utf8) else { return }

        webSocketTask?.send(.string(jsonString)) { error in
            if let error = error {
                Task { @MainActor in
                    self.onError?(error)
                }
            }
        }
    }

    private func authenticate(accessToken: String) async throws {
        send(message: ["type": "auth", "access_token": accessToken])
    }

    private func sendRefreshToken() {
        if let refresh = apiManager.refreshToken {
            send(message: ["type": "auth", "refresh_token": refresh])
        }
    }

    public func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        onDone?()
    }

    public func subscribe() {
        for sub in subscriptionDataList {
            send(message: sub.toJson())
        }
    }

    public func addSubscription(
        _ subscription: any AnyDirectusWebSocketSubscription
    ) {
        subscriptionDataList.append(subscription)
        send(message: subscription.toJson())
    }

    public func removeSubscription(uid: String) {
        send(message: ["type": "unsubscribe", "uid": uid])
    }
}
