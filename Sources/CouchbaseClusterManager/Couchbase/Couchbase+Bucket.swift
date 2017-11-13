//
//  Couchbase+Bucket.swift
//  CouchbaseClusterManagerPackageDescription
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

    public func create(bucket name: String, memoryQuota: UInt, authType: String = "none") throws {

        let request = Request(method: .post, uri: self.uri.appendingPathComponent("/pools/default/buckets"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        request.formURLEncoded = [
            "name": Vapor.Node(name),
            "ramQuotaMB": Vapor.Node(memoryQuota),
            "authType": Vapor.Node(authType)
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

    public func info(forBucket name: String) throws -> JSON {

        let request = Request(method: .get, uri: self.uri.appendingPathComponent("/pools/default/buckets/\(name)"))

        request.headers[HeaderKey.authorization] = self.credentials?.httpBasicAuth

        let response = try self.client.respond(to: request)

        switch response.status.statusCode {
        case 200...299:
            guard let json = response.json else {
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

    public func exists(bucket name: String) throws -> Bool {

        do {
            _ = try self.info(forBucket: name)

            return true

        } catch let error as Couchbase.Error {

            switch error {
            case .bucketNotFound:
                return false
            default:
                throw error
            }

        } catch {
            throw error
        }
    }
}
