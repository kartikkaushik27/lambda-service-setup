#!/usr/bin/env python3
"""Extract per-lambda deploy info from a self-service environments/*.tfvars file.

Used by the multi-environment pipeline's "Create Workspaces" step
(templates/multi-env-pipeline.yaml.tftpl) to build the list of items the
Deploy stage's looping strategy iterates over, without needing a real HCL
parser. Brace-matched, so it does not depend on indentation - only on the
schema in iacm/variables.tf (a top-level `harness { }` block and a top-level
`lambdas { }` map, each lambda optionally keyed by region under
`artifact_by_region`).

Usage: parse_lambdas.py <tfvars-file> <region>
Prints one JSON object: {"aws_connector_id": ..., "lambdas": [...]}
`lambdas` only includes entries that publish an artifact for <region> -
a lambda not deployed to this region is silently omitted.
"""
import json
import re
import sys


def find_block(text, key):
    """Return the content between the braces of the first top-level `key = {`."""
    m = re.search(r"(?m)^\s*" + re.escape(key) + r"\s*=\s*\{", text)
    if not m:
        return None
    depth = 1
    i = m.end()
    start = i
    while i < len(text) and depth > 0:
        if text[i] == "{":
            depth += 1
        elif text[i] == "}":
            depth -= 1
        i += 1
    return text[start : i - 1]


def direct_children(block_text):
    """Map of key -> content for every `key = { ... }` at depth 0 of block_text."""
    if not block_text:
        return {}
    children = {}
    pattern = re.compile(r'([A-Za-z_"][A-Za-z0-9_\-"]*)\s*=\s*\{')
    depth = 0
    pos = 0
    n = len(block_text)
    while pos < n:
        ch = block_text[pos]
        if ch == "{":
            depth += 1
            pos += 1
            continue
        if ch == "}":
            depth -= 1
            pos += 1
            continue
        if depth == 0:
            m = pattern.match(block_text, pos)
            if m:
                key = m.group(1).strip('"')
                d = 1
                j = m.end()
                start = j
                while j < n and d > 0:
                    if block_text[j] == "{":
                        d += 1
                    elif block_text[j] == "}":
                        d -= 1
                    j += 1
                children[key] = block_text[start : j - 1]
                pos = j
                continue
        pos += 1
    return children


def scalar(block_text, key):
    if not block_text:
        return None
    m = re.search(r'(?m)^\s*' + re.escape(key) + r'\s*=\s*"([^"]*)"', block_text)
    return m.group(1) if m else None


def main():
    path, region = sys.argv[1], sys.argv[2]
    text = open(path).read()

    harness_block = find_block(text, "harness")
    aws_connector_id = scalar(harness_block, "aws_connector_id")

    lambdas_block = find_block(text, "lambdas")
    lambdas = direct_children(lambdas_block)

    out = []
    for key, body in lambdas.items():
        abr_block = direct_children(body).get("artifact_by_region")
        region_body = direct_children(abr_block).get(region) if abr_block else None
        if region_body is None:
            continue  # this lambda is not deployed to this region

        out.append(
            {
                "key": key,
                "function_name": scalar(body, "function_name"),
                "service_identifier": scalar(body, "service_identifier"),
                "artifact_source_identifier": scalar(body, "artifact_source_identifier"),
                "bucket": scalar(region_body, "bucket"),
                "object_key": scalar(region_body, "key"),
            }
        )

    print(json.dumps({"aws_connector_id": aws_connector_id, "lambdas": out}))


if __name__ == "__main__":
    main()
