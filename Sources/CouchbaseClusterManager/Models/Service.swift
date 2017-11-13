//
//  Service.swift
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
import Vapor

public struct Service {

    public let name: String

    public let replicas: Int

    public let port: UInt16

    public let cluster: String

    /// Short hostnames are not allowed.
    public let hostname: String

    public let services: String

    public init(
        name: String,
        replicas: Int,
        port: UInt16? = nil,
        cluster: String,
        hostname: String,
        services: String
    ) {
        self.name = name
        self.replicas = replicas
        self.port = port ?? 8091
        self.cluster = cluster
        self.hostname = hostname
        self.services = services
    }

    public var uri: URI {
        return URI(scheme: "http", hostname: self.hostname, port: self.port)
    }
}

extension Service: Equatable {

    public static func == (lhs: Service, rhs: Service) -> Bool {
        return lhs.name == rhs.name &&
            lhs.replicas == rhs.replicas &&
            lhs.port == rhs.port &&
            lhs.cluster == rhs.cluster &&
            lhs.hostname == rhs.hostname &&
            lhs.services == rhs.services
    }
}

extension Service: Hashable {

    public var hashValue: Int {
        return self.name.hashValue
    }
}
