//
//  Config.swift
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

public struct Config {

    public let cluster: Cluster

    public let bucket: Bucket?

    public let syncGatewayUser: SyncGatewayUser?

    /// Time interval in between manager checks, in seconds.
    public let interval: UInt32

    public init(
        cluster: Cluster,
        bucket: Bucket?,
        syncGatewayUser: SyncGatewayUser?,
        interval: UInt32
    ) {
        self.cluster = cluster
        self.bucket = bucket
        self.syncGatewayUser = syncGatewayUser
        self.interval = interval
    }

    public init() throws {

        var interval: UInt32 = 300

        if let intervalString: String = ProcessInfo.processInfo.environment["CCM_INTERVAL"] {

            guard let intervalUInt32: UInt32 = UInt32(intervalString) else {
                throw Error.invalidKey("CCM_INTERVAL")
            }

            interval = intervalUInt32
        }

        self.init(
            cluster: try Cluster(),
            bucket: try? Bucket(),
            syncGatewayUser: try? SyncGatewayUser(),
            interval: interval
        )
    }
}

public extension Config {

    public struct Cluster {

        /**
         The cluster's name.

         The manager will try to consolidate all services that match the name, into the same cluster.
         */
        public let name: String

        public let username: String

        public let password: String

        public let memoryQuota: UInt

        public let indexMemoryQuota: UInt

        public let ftsMemoryQuota: UInt

        public init(
            name: String,
            username: String,
            password: String,
            memoryQuota: UInt,
            indexMemoryQuota: UInt,
            ftsMemoryQuota: UInt
        ) {
            self.name = name
            self.username = username
            self.password = password
            self.memoryQuota = memoryQuota
            self.indexMemoryQuota = indexMemoryQuota
            self.ftsMemoryQuota = ftsMemoryQuota
        }

        public init() throws {

            guard let name: String = ProcessInfo.processInfo.environment["CCM_NAME"] else {
                throw Error.invalidKey("CCM_NAME")
            }

            guard let username: String = ProcessInfo.processInfo.environment["CCM_USERNAME"] else {
                throw Error.invalidKey("CCM_USERNAME")
            }

            guard let passwordRaw: String = ProcessInfo.processInfo.environment["CCM_PASSWORD"] else {
                throw Error.invalidKey("CCM_PASSWORD")
            }

            guard let memoryQuotaRaw: String = ProcessInfo.processInfo.environment["CCM_MEMORY_QUOTA"],
                let memoryQuota = UInt(memoryQuotaRaw)
                else {
                    throw Error.invalidKey("CCM_MEMORY_QUOTA")
            }

            guard let indexMemoryQuotaRaw: String = ProcessInfo.processInfo.environment["CCM_INDEX_MEMORY_QUOTA"],
                let indexMemoryQuota = UInt(indexMemoryQuotaRaw)
                else {
                    throw Error.invalidKey("CCM_INDEX_MEMORY_QUOTA")
            }

            guard let ftsMemoryQuotaRaw: String = ProcessInfo.processInfo.environment["CCM_FTS_MEMORY_QUOTA"],
                let ftsMemoryQuota = UInt(ftsMemoryQuotaRaw)
                else {
                    throw Error.invalidKey("CCM_FTS_MEMORY_QUOTA")
            }

            self.init(
                name: name,
                username: username,
                password: (try? Data(contentsOf: URL(fileURLWithPath: passwordRaw)).makeString()) ?? passwordRaw,
                memoryQuota: memoryQuota,
                indexMemoryQuota: indexMemoryQuota,
                ftsMemoryQuota: ftsMemoryQuota
            )
        }
    }
}

public extension Config {

    public struct Bucket {

        public let name: String

        public let memoryQuota: UInt

        public init(
            name: String,
            memoryQuota: UInt
        ) {
            self.name = name
            self.memoryQuota = memoryQuota
        }

        public init() throws {

            guard let name: String = ProcessInfo.processInfo.environment["CCM_BUCKET_NAME"] else {
                throw Error.invalidKey("CCM_BUCKET_NAME")
            }

            guard let memoryQuotaRaw: String = ProcessInfo.processInfo.environment["CCM_BUCKET_MEMORY_QUOTA"],
                let memoryQuota = UInt(memoryQuotaRaw)
                else {
                    throw Error.invalidKey("CCM_BUCKET_MEMORY_QUOTA")
            }

            self.init(
                name: name,
                memoryQuota: memoryQuota
            )
        }
    }
}

public extension Config {

    public struct SyncGatewayUser {

        public let username: String

        public let password: String

        public init(
            username: String,
            password: String
        ) {
            self.username = username
            self.password = password
        }

        public init() throws {

            guard let username: String = ProcessInfo.processInfo.environment["CCM_SG_USERNAME"] else {
                throw Error.invalidKey("CCM_SG_USERNAME")
            }

            guard let password: String = ProcessInfo.processInfo.environment["CCM_SG_PASSWORD"] else {
                throw Error.invalidKey("CCM_SG_PASSWORD")
            }

            self.init(
                username: username,
                password: password
            )
        }
    }
}

public extension Config {

    public enum Error: Swift.Error {
        case invalidKey(String)
    }
}
