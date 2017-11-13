//
//  Couchbase+User.swift
//  CouchbaseClusterManager
//
//  Created by Valerio Mazzeo on 13/11/2017.
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

    public enum AuthDomain: String {
        case local
        case external
    }

    public func users() throws -> [JSON] {

        let request = Request(method: .get, uri: self.uri.appendingPathComponent("/settings/rbac/users"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            guard let json = response.json?.array else {
                throw Error.other("Invalid response body.")
            }

            return json
        case 401:
            throw Error.unauthorized
        case 404:
            throw Error.bucketNotFound
        default:
            throw Error.unknown(response)
        }
    }

    public func exists(user name: String) throws -> Bool {

        let users = try self.users()

        return users.contains(where: { $0["id"]?.string == name })
    }

    public func create(user name: String, password: String, roles: String, authDomain: AuthDomain = .local) throws {

        let request = Request(method: .put, uri: self.uri.appendingPathComponent("/settings/rbac/users/\(authDomain.rawValue)/\(name)"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = [
            "name": Vapor.Node(name),
            "password": Vapor.Node(password),
            "roles": Vapor.Node(roles)
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

    public func set(roles: String, for user: String) throws {

        let request = Request(method: .put, uri: self.uri.appendingPathComponent("/settings/rbac/users/\(user)"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = ["roles": Vapor.Node(roles)]

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
