//
//  Couchbase+Credentials.swift
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

    public struct Credentials {

        public let username: String

        public let password: String

        public init(username: String, password: String) {
            self.username = username
            self.password = password
        }

        public var httpBasicAuth: String? {

            guard let encodedCredentials = "\(self.username):\(self.password)".data(using: .utf8)?.base64EncodedString() else {
                return nil
            }

            return "Basic \(encodedCredentials)"
        }
    }
}

public extension Couchbase {

    public func set(credentials: Credentials) throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/settings/web"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = [
            "username": Vapor.Node(credentials.username),
            "password": Vapor.Node(credentials.password),
            "port": Vapor.Node(String(self.uri.port ?? 8091))
        ]

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
