//
//  Couchbase+Node.swift
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

    public func set(hostname: String) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/node/controller/rename"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["hostname": Vapor.Node(hostname)]

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

    public func set(services: ServiceOptions) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/node/controller/setupServices"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["services": Vapor.Node(services.makeString())]

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
}

public extension Couchbase {

    public struct Node {

        public let memoryTotal: Int

        public let memoryFree: Int

        public let couchApiBase: String

        public let clusterMembership: String

        public let status: String

        public let otpNode: String

        public let hostname: String

        public let version: String

        public init(
            memoryTotal: Int,
            memoryFree: Int,
            couchApiBase: String,
            clusterMembership: String,
            status: String,
            otpNode: String,
            hostname: String,
            version: String
        ) {
            self.memoryTotal = memoryTotal
            self.memoryFree = memoryFree
            self.couchApiBase = couchApiBase
            self.clusterMembership = clusterMembership
            self.status = status
            self.otpNode = otpNode
            self.hostname = hostname
            self.version = version
        }
    }
}

extension Couchbase.Node: JSONInitializable {

    public init(json: JSON) throws {

        self.init(
            memoryTotal: try json.get("memoryTotal"),
            memoryFree: try json.get("memoryFree"),
            couchApiBase: try json.get("couchApiBase"),
            clusterMembership: try json.get("clusterMembership"),
            status: try json.get("status"),
            otpNode: try json.get("otpNode"),
            hostname: try json.get("hostname"),
            version: try json.get("version")
        )
    }
}
