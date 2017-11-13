//
//  DockerServiceDataSource.swift
//  CouchbaseClusterManager
//
//  Created by Valerio Mazzeo on 09/11/2017.
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
import JSON
import Vapor
import HTTP
import DockerClient

public class DockerServiceDataSource: ServiceDataSource {

    // MARK: Initialization

    public init() {

    }

    // MARK: Accessing Attributes

    private let client = DockerClient()

    // MARK: ServiceDataSource

    public func fetch() throws -> Set<Service> {

        guard let url = URL(string: "http:/v1.32/services?filters={\"label\":[\"com.ccm.cluster\"]}".urlQueryPercentEncoded) else {
            throw URLError(.badURL)
        }

        let response = try self.client.respond(to: URLRequest(url: url))

        guard let body = response.body else {
            throw Error.invalidData
        }

        let jsonBody = try JSON(bytes: body)

        guard let array = jsonBody.array else {
            throw Error.invalidData
        }

        return Set(array.flatMap({ json in

            do {
                let labels: JSON = try json.get("Spec.Labels")

                guard
                    let cluster = labels[DotKey("com.ccm.cluster")]?.string,
                    let hostname = labels[DotKey("com.ccm.hostname")]?.string,
                    let services = labels[DotKey("com.ccm.services")]?.string
                    else {
                        return nil
                }

                return Service(
                    name: try json.get("Spec.Name"),
                    replicas: try json.get("Spec.Mode.Replicated.Replicas"),
                    port: UInt16(labels[DotKey("com.ccm.port")]?.uint ?? 8091),
                    cluster: cluster,
                    hostname: hostname,
                    services: services
                )
            } catch {
                return nil
            }
        }))
    }
}

public extension DockerServiceDataSource {

    public enum Error: Swift.Error {
        case invalidData
    }
}
