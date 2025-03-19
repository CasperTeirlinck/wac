#!/bin/bash
# Assume an IAM role
# Usage: `login_add_aws_role_profile.sh --profile myprofile --source-profile default --role-arn arn:aws:iam::<account-id>:role/<role>`

profile=""
source_profile=""
role=""
while [[ $# -gt 0 ]]; do
    case "$1" in
    -p | --profile)
        profile="$2"
        shift 2
        ;;
    -s | --source-profile)
        source_profile="$2"
        shift 2
        ;;
    -r | --role-arn)
        role="$2"
        shift 2
        ;;
    *)
        echo "Invalid option: ${1:-}"
        exit 1
        ;;
    esac
done

if [[ -z $role ]] || [[ -z $profile ]] || [[ -z $source_profile ]]; then
    echo "Required arguments: '--profile', '--source-profile', '--role-arn'"
    exit 1
fi

aws configure set profile.$profile.role_arn $role
aws configure set profile.$profile.source_profile $source_profile
