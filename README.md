# couchbase-cluster-manager

![Swift](https://img.shields.io/badge/swift-4.0.2-orange.svg)
![Platform](https://img.shields.io/badge/platform-OSX-lightgrey.svg)
![Platform](https://img.shields.io/badge/platform-Linux-lightgrey.svg)

Docker container for Couchbase Server cluster provisioning and configuration.

## Overview

Couchbase Cluster Manager is a Docker container running an application written in Swift.
It's purpose is to automatically manage a cluster of Couchbase Server nodes running on a Docker swarm.

### Features

- Automatically provision a new cluster from scratch.
- Add nodes to a cluster.
- Remove failed nodes from a cluster.
- Rebalance the cluster.

### How it works

**Glossary:**
- `Node`: a couchbase server instance.
- `Service`: a docker swarm service, running a couchbase server container (a node).

Couchbase Cluster Manager communicates directly with Docker Swarm and retrieves a list of running services at regular intervals (`CCM_INTERVAL`). The list is then filtered based on its `com.ccm.cluster` label to match the manager's `CCM_NAME` environment variable. It then proceeds to find an already provisioned node, if none is found a new cluster get initialized using the configuration specified on the container environment. At this stage a bucket named `CCM_BUCKET_NAME` and a sync gateway user `CCM_SG_USERNAME` /  `CCM_SG_PASSWORD` are created, if defined in the configuration.

Couchbase Cluster Manager now has access to a provisioned node in the cluster, and it proceeds to retrieve a list of well known nodes, in order to work out which ones have been removed and which ones have to be added. It does this, comparing the hostnames on the service list with the node's hostnames.

At this point, nodes matching services that are no longer presents on the Swarm are `failed over`, meanwhile services running on the Swarm, but not matching any node, are `added` to the cluster. Once all nodes are processed a `rebalance` is triggered (if needed).

**Note:** Couchbase Cluster Manager must run on a docker swarm manager (`constraints: [node.role == manager]`) and and must bind to `/var/run/docker.sock` in order to communicate with Docker Swarm and being able to retrieve a list of services.

## Configuration

### Container Environment Variables

| Name    | Required | Default | Value (e.g.) | Description |
| ------------- |:-------------:|:-------------:|:-------------:|:-------------|
| `CCM_NAME` | ✔ | `-` | `my-cluster` | Cluster name. |
| `CCM_MEMORY_QUOTA`       | ✔ | `-` | `512` | Cluster memory memory quota (MB). |
| `CCM_INDEX_MEMORY_QUOTA`     | ✔ | `-` | `256` | Cluster index memory quota (MB). |
| `CCM_FTS_MEMORY_QUOTA`     | ✔ | `-` | `256` | Cluster full text search memory quota (MB). |
| `CCM_USERNAME`     | ✔ | `-` | `admin` | Cluster administration username. |
| `CCM_PASSWORD`     | ✔ | `-` | `/run/secrets/ccm_password` | Cluster administration password (plain text or secret). |
| `CCM_BUCKET_NAME`     | `-` | `-` | `default` | Bucket name. |
| `CCM_BUCKET_MEMORY_QUOTA`  | `-` | `-` | `512` | Bucket memory quota (MB). |
| `CCM_SG_USERNAME`  | `-` | `-` | `syncgateway` | SyncGateway username. |
| `CCM_SG_PASSWORD`  | `-` | `-` | `password` | SyncGateway password. |
| `CCM_INTERVAL`     | `-` | `300` | `60` | Manager node consolidation interval (seconds). |

### Service Labels

| Name    | Required | Value (e.g.) | Description |
| ------------- |:-------------:|:-------------:|:-------------|
| `com.ccm.cluster` | ✔ | `my-cluster` | Cluster name, must match `CCM_NAME`. |
| `com.ccm.hostname`       | ✔ | `node-01.my-cluster` | Service hostname (must contain at least one `.`). |
| `com.ccm.services`     | ✔ | `data,index,query,fts` | Couchbase services to configure on the node. |

## Docker Compose

The following stack will start two couchbase server nodes and one couchbase-cluster-manager.

`docker-compose.yml`
```
version: '3.3'
services:

  cbs-01:
    image: couchbase/server:community-5.0.0
    networks:
      default:
        aliases:
          - cbs-01.mycluster
    deploy:
      labels:
        com.ccm.cluster: "mycluster"
        com.ccm.hostname: "cbs-01.mycluster"
        com.ccm.services: "data,index,query,fts"

  cbs-02:
    image: couchbase/server:community-5.0.0
    networks:
      default:
        aliases:
          - cbs-02.mycluster
    deploy:
      labels:
        com.ccm.cluster: "mycluster"
        com.ccm.hostname: "cbs-02.mycluster"
        com.ccm.services: "data,index,query,fts"

  cbs-cluster-manager:
    image: asensei/couchbase-cluster-manager
    environment:
      - CCM_NAME=mycluster
      - CCM_MEMORY_QUOTA=512
      - CCM_INDEX_MEMORY_QUOTA=256
      - CCM_FTS_MEMORY_QUOTA=256
      - CCM_USERNAME=administrator
      - CCM_PASSWORD=password
      - CCM_BUCKET_NAME=default
      - CCM_BUCKET_MEMORY_QUOTA=512
      - CCM_SG_USERNAME=syncgateway
      - CCM_SG_PASSWORD=password
      - CCM_INTERVAL=300
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    deploy:
      placement:
        constraints: [node.role == manager]

  networks:
    default:
```
