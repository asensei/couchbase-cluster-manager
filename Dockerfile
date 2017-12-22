FROM asensei/vapor:xenial-swift-4.0.3

# Set environment variables for image
ENV HOME /couchbase-cluster-manager
ENV WORK_DIR /couchbase-cluster-manager

# Set WORKDIR
WORKDIR ${WORK_DIR}

# Linux OS utils and libraries
RUN apt-get update && apt-get install -y \
  libcurl4-openssl-dev \
  && rm -r /var/lib/apt/lists/*

# Install Couchbase Cluster Manager
ADD . /${WORK_DIR}
RUN  swift build -c release

# Run Unsu
CMD .build/release/Run serve --env=$ENVIRONMENT
