//
//  Couchbase+Cluster.swift
//  CouchbaseClusterManager
//
//  Created by Valerio Mazzeo on 10/11/2017.
//  Copyright © 2017 Asensei Inc. All rights reserved.
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU Lesser General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
//  See the GNU Lesser General Public License for more details.
//
//  You should have received a copy of the GNU Lesser General Public License
//  along with this program. If not, see <http://www.gnu.org/licenses/>.
//

import Foundation
import HTTP
import Vapor

public extension Couchbase {

    public func provision(
        hostname: String,
        credentials: Credentials,
        memoryQuota: UInt,
        indexMemoryQuota: UInt,
        ftsMemoryQuota: UInt,
        services: ServiceOptions,
        storageMode: StorageMode = .forestdb
        ) throws {

        try self.set(hostname: hostname)
        try self.set(memoryQuota: memoryQuota)
        try self.set(indexMemoryQuota: indexMemoryQuota)
        try self.set(ftsMemoryQuota: ftsMemoryQuota)
        try self.set(services: services)
        try self.set(storageMode: storageMode)
        try self.set(credentials: credentials)
    }

    public func isProvisioned() throws -> Bool {

        let request = Request(method: .get, uri: self.uri.appendingPathComponent("/pools/default"))

        let response = try self.client.respond(to: request)

        return response.status == .unauthorized
    }

    @discardableResult
    public func add(node hostname: String, username: String, password: String, services: ServiceOptions) throws -> String {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/controller/addNode"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = [
            "hostname": Vapor.Node(hostname),
            "user": Vapor.Node(username),
            "password": Vapor.Node(password),
            "services": Vapor.Node(services.makeString())
        ]

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:

            guard let otpNode = response.json?["otpNode"]?.string else {
                throw Error.other("Invalid otpNode data.")
            }

            return otpNode

        case 401:
            throw Error.unauthorized
        default:
            throw Error.unknown(response)
        }
    }

    public func failover(otpNode: String) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/controller/failOver"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["otpNode": Vapor.Node(otpNode)]

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            return
        case 401:
            throw Error.unauthorized
        default:
            throw Error.unknown(response)
        }
    }

    public func rebalance(otpKnownNodes: [String], otpEjectedNodes: [String]) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/controller/rebalance"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        var formURLEncoded: [String: Vapor.Node] = [:]

        if !otpKnownNodes.isEmpty {
            formURLEncoded["knownNodes"] = Vapor.Node(otpKnownNodes.joined(separator: ","))
        }

        if !otpEjectedNodes.isEmpty {
            formURLEncoded["ejectedNodes"] = Vapor.Node(otpEjectedNodes.joined(separator: ","))
        }

        request.formURLEncoded = formURLEncoded.isEmpty ? nil : Vapor.Node(formURLEncoded)

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            return
        case 401:
            throw Error.unauthorized
        default:
            throw Error.unknown(response)
        }
    }

    public func nodes() throws -> [Couchbase.Node] {

        let request = Request(method: .get, uri: self.uri.appendingPathComponent("/pools/nodes"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:

            guard let nodes = response.json?["nodes"]?.array else {
                throw Error.other("Invalid nodes data.")
            }

            return try nodes.map({ try Couchbase.Node(json: $0) })
        case 401:
            throw Error.unauthorized
        default:
            throw Error.unknown(response)
        }
    }

    // MARK: RAM

    public func set(memoryQuota: UInt) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/pools/default"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["memoryQuota": Vapor.Node(memoryQuota)]

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            return
        case 401:
            throw Error.unauthorized
        case 400:
            throw Error.memoryQuotaTooSmall
        default:
            throw Error.unknown(response)
        }
    }

    public func set(indexMemoryQuota: UInt) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/pools/default"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["indexMemoryQuota": Vapor.Node(indexMemoryQuota)]

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            return
        case 401:
            throw Error.unauthorized
        case 400:
            throw Error.indexMemoryQuotaTooSmall
        default:
            throw Error.unknown(response)
        }
    }

    public func set(ftsMemoryQuota: UInt) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/pools/default"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["ftsMemoryQuota": Vapor.Node(ftsMemoryQuota)]

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            return
        case 401:
            throw Error.unauthorized
        case 400:
            throw Error.ftsMemoryQuotaTooSmall
        default:
            throw Error.unknown(response)
        }
    }
}
