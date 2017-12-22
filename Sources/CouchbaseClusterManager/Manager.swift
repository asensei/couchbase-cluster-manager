//
//  Manager.swift
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
#if os(Linux)
    import Glibc
#else
    import Darwin.C
#endif

public class Manager {

    // MARK: Initialization

    public required init(_ config: Config, dataSource: ServiceDataSource) {

        self.config = config
        self.dataSource = dataSource
    }

    public convenience init(_ config: Config) throws {

        self.init(config, dataSource: DockerServiceDataSource())
    }

    // MARK: Accessing Attributes

    private let config: Config

    public let dataSource: ServiceDataSource

    // MARK: Run

    public func run() {

        while true {

            do {
                try self.runIteration()
            } catch {
                print("Error: \(error)")
            }

            fflush(stdout)

            sleep(self.config.interval)
        }
    }

    func runIteration() throws {

        let services = try self.dataSource
            .fetch()
            .filter({ $0.cluster == self.config.cluster.name })

        // Get any already provisioned service, if none try to provision the first, initializing a new cluster.
        let cluster = try self.cluster(in: services)
        cluster.credentials = Couchbase.Credentials(username: self.config.cluster.username, password: self.config.cluster.password)

        // Create bucket if needed
        if let bucketConfig = self.config.bucket, try !cluster.exists(bucket: bucketConfig.name) {
            print("Creating bucket \(bucketConfig.name)")
            try cluster.create(bucket: bucketConfig.name, memoryQuota: bucketConfig.memoryQuota)
        }

        // Create SyncGateway user if needed
        if let syncGatewayUserConfig = self.config.syncGatewayUser, try !cluster.exists(user: syncGatewayUserConfig.username) {
            print("Creating sync gateway user \(syncGatewayUserConfig.username)")
            try cluster.create(user: syncGatewayUserConfig.username, password: syncGatewayUserConfig.password, roles: "bucket_full_access[*],ro_admin")
        }

        // Retrieve all current cluster nodes
        let nodes = try cluster.nodes()

        // Evaluate added services
        let addedServices = services.filter({ service in

            return !nodes.contains(where: { service == $0 })
        })

        // Evaluate nodes that have to be removed
        let removedNodes = nodes.filter({ node in

            return !services.contains(where: { $0 == node })
        })

        if !addedServices.isEmpty || !removedNodes.isEmpty {
            // Log summary
            print("Nodes: \(nodes.count)\nServices:\n- Total: \(services.count)\n- Added: \(addedServices.count)\n- Removed: \(removedNodes.count)")
        }

        // Add new services to the cluster
        for service in addedServices {

            print("Adding \(service.name) to cluster \(self.config.cluster.name) through \(cluster.uri)")

            do {
                try cluster.add(
                    node: service.hostname,
                    username: self.config.cluster.username,
                    password: self.config.cluster.password,
                    services: Couchbase.ServiceOptions(stringValue: service.services)
                )
            } catch {
                print("Error: \(error)")
            }
        }

        // Flag failed nodes
        var removedOtpNodes: [String] = []

        for node in removedNodes {

            do {
                print("Removing \(node.hostname) from cluster \(self.config.cluster.name)")
                try cluster.failover(otpNode: node.otpNode)
                removedOtpNodes.append(node.otpNode)
            } catch {
                print("Error: \(error)")
            }
        }

        let knownNodes = try cluster.nodes()

        if !knownNodes.filter({ $0.clusterMembership != "active" }).isEmpty || !removedOtpNodes.isEmpty {

            print("Rebalancing cluster")

            try cluster.rebalance(
                otpKnownNodes: knownNodes.map({ $0.otpNode }),
                otpEjectedNodes: removedOtpNodes
            )
        }
    }

    private func cluster(in services: Set<Service>) throws -> Couchbase {

        if let service = try services.first(where: { service in

            try service.makeCouchbase().isProvisioned()
        }) {
            return service.makeCouchbase()
        }

        let credentials = Couchbase.Credentials(username: self.config.cluster.username, password: self.config.cluster.password)

        // Initialize a new cluster
        guard let cluster = try services.first(where: { service in

            try service.makeCouchbase().provision(
                hostname: service.hostname,
                credentials: credentials,
                memoryQuota: self.config.cluster.memoryQuota,
                indexMemoryQuota: self.config.cluster.indexMemoryQuota,
                ftsMemoryQuota: self.config.cluster.ftsMemoryQuota,
                services: Couchbase.ServiceOptions(stringValue: service.services)
            )

            return true

        })?.makeCouchbase() else {
            throw Error.clusterInitializationError
        }

        return cluster
    }
}

public extension Manager {

    public enum Error: Swift.Error {
        case clusterInitializationError
    }
}

private extension Service {

    func makeCouchbase() -> Couchbase {
        return Couchbase(uri: self.uri)
    }
}

public func == (lhs: Service, rhs: Couchbase.Node) -> Bool {
    return lhs.hostname + ":" + String(lhs.port) == rhs.hostname
}
