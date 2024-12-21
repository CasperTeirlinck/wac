#!/bin/bash

profile=""
cluster=""
name=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    -h | --help)
        echo "Usage: $0 --cluster <cluster-name> --name <context-name>"
        exit 0
        ;;
    --profile)
        profile="$2"
        shift 2
        ;;
    --cluster)
        cluster="$2"
        shift 2
        ;;
    --name)
        name="$2"
        shift 2
        ;;
    *)
        echo "Invalid option: ${1:-}"
        exit 1
        ;;
    esac
done

if [[ -z $cluster ]] || [[ -z $name ]]; then
    echo "Required arguments: '--cluster' and '--name'"
    exit 1
fi
if [[ -z $profile ]]; then
    echo "No AWS profile specified, make sure you have AWS_PROFILE set"
else
    export AWS_PROFILE=$profile
fi

aws eks update-kubeconfig --name $cluster
arn=$(aws eks describe-cluster --name $cluster --query cluster.arn --output text)
kubectl config delete-context $name || :
kubectl config rename-context $arn $name