# Up
    # ARM Bento boxes currently need VirtualBox 7.1.6+.
    # Optional: override the base box/version if you need to pin a known-good image.
    #   export SWARM_TEST_BOX=bento/ubuntu-22.04
    #   export SWARM_TEST_BOX_VERSION=<known-good-version>
    vagrant up manager1
    vagrant up manager2 worker1 worker2

# Run swarm-dashboard (image from Docker Hub)
    vagrant ssh manager1
    docker stack deploy -c /vagrant/compose-all.yml sd

# Run swarm-dashboard (build locally)
    vagrant ssh manager1
    docker stack deploy -c /vagrant_parent/test-cluster/compose-metrics.yml sd
    docker compose -f /vagrant_parent/test-cluster/compose-dashboard.yml up --build

# Run swarm-dashboard from a host-built image
# Use this path on ARM hosts, because Elm 0.18 does not provide linux-arm64 binaries.
    docker build --platform=linux/amd64 -t swarm-dashboard:test-cluster-amd64 .
    ./test-cluster/export-client-assets.sh swarm-dashboard:test-cluster-amd64
    docker build -f Dockerfile.test-cluster -t swarm-dashboard:test-cluster-arm64 .
    docker save swarm-dashboard:test-cluster-arm64 | vagrant ssh manager1 -c 'docker load'
    vagrant ssh manager1
    docker stack deploy -c /vagrant_parent/test-cluster/compose-metrics.yml sd
    SWARM_DASHBOARD_IMAGE=swarm-dashboard:test-cluster-arm64 docker compose -f /vagrant_parent/test-cluster/compose-dashboard-image.yml up

# Shutdown
    vagrant halt

# Destroy
    vagrant destroy -f
