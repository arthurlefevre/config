#! /bin/bash

function newincmd() { 
   declare args 
   # escape single & double quotes 
   args="${@//\'/\'}" 
   args="${args//\"/\\\"}" 
   printf "%s" "${args}" | /usr/bin/pbcopy 
   #printf "%q" "${args}" | /usr/bin/pbcopy 
   /usr/bin/open -a Terminal 
   /usr/bin/osascript -e 'tell application "Terminal" to do script with command "/usr/bin/clear; eval \"$(/usr/bin/pbpaste)\""' 
   return 0 
}

function start_registry () {
    STATUS=$( docker container inspect -f '{{.State.Status}}' registry )
    if [ "$STATUS" != "running" ];
    then
        docker run -d -p 5001:5000 --restart=always --name="registry" --volume ~/.registry/storage:/var/lib/registry registry:2
        HOST_PATH="/etc/hosts"
        REGISTRY_HOST="127.0.0.1 registry.dev.svc.cluster.local"
        DOCKER_DEMON="$HOME/.docker/daemon.json"
        echo $DOCKER_DEMON
        if ! grep -q "$REGISTRY_HOST" "$HOST_PATH"; then
            echo "$REGISTRY_HOST" | sudo tee -a /etc/profile > /dev/null
        fi
        #cat "$DOCKER_DEMON" | jq '. | if .insecure-registries == null then .insecure-registries = [] else empty end'
        #cat "$DOCKER_DEMON" | jq '. 
        #    | select(.insecure-registries != null) 
        #    | .insecure-registries[.insecure-registries| length]
        #    |= (. + "registry.dev.svc.cluster.local:5001" | unique) '
    fi
}

function check_dependencies () {
    TOOLS=("docker" "kubectl" "minikube" "jq" "helm" "kn")
    for tool in "${TOOLS[@]}"; do
        if ! command -v "$tool" >/dev/null 2>&1; then
            echo "$tool could not be found"
            exit 1
        fi
    done
    echo "All tools found"
}

function start () {
    echo "Checkings tools dependencies"
    check_dependencies
    echo "Starting local registry"
    start_registry
    echo "Local registry started"
    echo "Starting minikube"
    minikube start --insecure-registry registry.dev.svc.cluster.local:5001 --addons=ingress
    echo "Minikube started"
    echo "Starting tunnel"
    newincmd minikube tunnel >/dev/null 2>&1;
    echo "Installing knative"
    install_knative
    install_mongo_db
}

function install_knative () {
    kubectl apply -f https://github.com/knative/operator/releases/download/knative-v1.8.1/operator.yaml
    kubectl apply -f src/kubernetes/knative_service.yaml
    IP=$(kubectl --namespace knative-serving get service kourier)
    kubectl apply -f https://github.com/knative/serving/releases/download/knative-v1.8.3/serving-default-domain.yaml
}

function install_mongo_db () {
    kubectl apply -n owlgrid -f ./kubernetes-mongodb
}

function cleanup () {
    docker stop registry
    docker rm registry
    kubectl delete KnativeServing knative-serving -n knative-serving
    kubectl delete KnativeEventing knative-eventing -n knative-eventing
    kubectl delete -f https://github.com/knative/operator/releases/download/knative-v1.8.1/operator.yaml
    kubectl delete "$(kubectl api-resources --namespaced=true --verbs=delete -o name | tr "\n" "," | sed -e 's/,$//')" --all
    minikube stop
}

c=$1
case "${c}" in
    init)
        echo "item = 1"
    ;;
    start)
        start
    ;;
    cleanup)
        cleanup
    ;;
    *)
        echo "No command recognized"
    ;;
esac
