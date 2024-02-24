# iac-docker-snb-k3s

Sandbox cluster

## Copy Kubernetes config file to Gitlab runner

    docker exec container-snb-glrunner-k1 /bin/bash -xe -c 'mkdir -p /home/gitlab-runner/.kube'
    cp .terraform/kube_config.yml /var/lib/docker/volumes/volume-snb-glrunner-k1-home/_data/.kube/config
    docker exec container-snb-glrunner-k1 /bin/bash -xe -c 'chown -R gitlab-runner: /home/gitlab-runner/.kube'
    
Then
    
    docker exec -it container-snb-glrunner-k1 /bin/bash
    su - gitlab-runner
    kubectl get pods --all-namespaces

(Optional) Expose port for public access (Spacelift etc.)

    iptables -t nat -A PREROUTING -i eth0 -p tcp --dport 49639 -j DNAT --to-destination 10.90.0.31:6443

List

    iptables -t nat -v -L -n --line-number

## Continue with

    iac-k3s-config-base
    iac-k3s-config-longhorn
    iac-k3s-config-logging
    iac-k3s-config-monitoring
    iac-k3s-config-teams

## Docker

    docker exec -it container-snb-k3s-slb /bin/bash    
    docker logs --follow container-snb-k3s-s1
    
    docker container stop container-snb-k3s-s1
    docker container delete container-snb-k3s-s1

## Debugging

    docker exec -it container-snb-k3s-s1 /bin/bash
    k3s kubectl get nodes,pods,services -A -o wide
    kubectl -n kube-system describe pod coredns-6799fbcd5-dr5f9
    cat /var/lib/rancher/k3s/agent/containerd/containerd.log

Helpers

    journalctl -fu docker.service


## Manual teardown

    docker stop container-snb-k3s-alb
    docker stop container-snb-k3s-slb
    docker stop container-snb-k3s-s1

    docker remove container-snb-k3s-alb
    docker remove container-snb-k3s-slb
    docker remove container-snb-k3s-s1

    docker volume remove volume-snb-k3s-longhorn
    docker volume remove volume-snb-k3s-server

# Fix   

    docker volume create volume-snb-k3s-longhorn
    docker volume create volume-snb-k3s-server
