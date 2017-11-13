//
//  Couchbase+ServiceOptions.swift
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

public extension Couchbase {

    public struct ServiceOptions: OptionSet {

        public let rawValue: Int

        static let data             = ServiceOptions(rawValue: 1 << 0)
        static let index            = ServiceOptions(rawValue: 1 << 1)
        static let query            = ServiceOptions(rawValue: 1 << 2)
        static let fullTextSearch   = ServiceOptions(rawValue: 1 << 3)

        static let all: ServiceOptions = [.data, .index, .query, fullTextSearch]

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public init(stringValue: String) {

            let options = stringValue.components(separatedBy: ",")

            var serviceOptions = ServiceOptions()

            for option in options {

                switch option {
                case "kv", "data":
                    serviceOptions.insert(.data)
                case "index":
                    serviceOptions.insert(.index)
                case "query", "n1ql":
                    serviceOptions.insert(.query)
                case "fullTextSearch", "fts":
                    serviceOptions.insert(.fullTextSearch)
                default:
                    continue
                }
            }

            self = serviceOptions
        }

        public func makeString() -> String {

            var options = [String]()

            if self.contains(.data) {
                options.append("kv")
            }

            if self.contains(.index) {
                options.append("index")
            }

            if self.contains(.query) {
                options.append("n1ql")
            }

            if self.contains(.fullTextSearch) {
                options.append("fts")
            }

            return options.joined(separator: ",")
        }
    }
}
