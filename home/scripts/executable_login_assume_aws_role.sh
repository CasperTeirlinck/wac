#!/bin/bash
# Assume an IAM role
# Usage: `source login_assume_aws_role.sh --role-arn arn:aws:iam::<account-id>:role/<role>`

role=""
while [[ $# -gt 0 ]]; do
    case "$1" in
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

if [[ -z $role ]]; then
    echo "Required arguments: '--role-arn'"
    exit 1
fi

export $(printf \
    "AWS_ACCESS_KEY_ID=%s AWS_SECRET_ACCESS_KEY=%s AWS_SESSION_TOKEN=%s" \
    $(aws sts assume-role \
    --role-arn $role \
    --role-session-name AWSCLI-Session \
    --query "Credentials.[AccessKeyId,SecretAccessKey,SessionToken]" \
    --output text)
)