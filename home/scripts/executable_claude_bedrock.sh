#!/bin/bash
# Run Claude Code with Bedrock

if ! aws sts get-caller-identity &> /dev/null; then
    echo "Error: Not authenticated with AWS"
    exit 1
fi

export CLAUDE_CODE_USE_BEDROCK=1

get_model_id() {
    local profile_name=$1
    local model_id
    model_id=$(aws bedrock list-inference-profiles \
        --query "inferenceProfileSummaries[?inferenceProfileName==\`${profile_name}\`].inferenceProfileId | [0]" \
        --output text)

    if [[ -z "${model_id}" || "${model_id}" == "None" ]]; then
        echo "Error: Could not find inference profile named '${profile_name}'" >&2
        exit 1
    fi

    echo "${model_id}"
}

ANTHROPIC_MODEL=$(get_model_id "EU Anthropic Claude Opus 4.5")
ANTHROPIC_SMALL_FAST_MODEL=$(get_model_id "EU Anthropic Claude Haiku 4.5")
export ANTHROPIC_MODEL
export ANTHROPIC_SMALL_FAST_MODEL

# Recommended output token settings for Bedrock
# https://code.claude.com/docs/en/amazon-bedrock#5-output-token-configuration
export CLAUDE_CODE_MAX_OUTPUT_TOKENS=4096
export MAX_THINKING_TOKENS=1024

claude "$@"
