//
//  Couchbase+Error.swift
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
import Vapor

public extension Couchbase {

    public enum Error: Swift.Error {
        case unauthorized
        case memoryQuotaTooSmall
        case indexMemoryQuotaTooSmall
        case ftsMemoryQuotaTooSmall
        case bucketNotFound
        case unknown(Response)
        case other(String)

        var localizedDescription: String {

            switch self {
            case .unauthorized:
                return "Unauthorized."
            case .memoryQuotaTooSmall:
                return "Memory quota is too small."
            case .indexMemoryQuotaTooSmall:
                return "Index memory quota is too small."
            case .ftsMemoryQuotaTooSmall:
                return "Full text search memory quota is too small."
            case .bucketNotFound:
                return "Bucket not found."
            case .unknown(let response):
                return "Status: \(response.status.statusCode). \(response.body.bytes?.makeString() ?? "")"
            case .other(let text):
                return text
            }
        }
    }
}
