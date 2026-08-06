#!/usr/bin/env python3
"""Discover a project's lambdas and its artifact bucket for one region.

Used by the multi-environment pipeline (templates/multi-env-pipeline.yaml.tftpl).
Lambdas are auto-discovered from lambda-src/<project>/* directories - not
declared in the tfvars file - so adding or removing a lambda-src directory is
the entire workflow for adding or removing a lambda. Each one's artifact is
assumed to live at <project>/<name>/lambda.zip in the tfvars file's
artifact_buckets[region].

Usage: parse_lambdas.py <tfvars-file> <region> <project>
Prints one JSON object: {"aws_connector_id": ..., "bucket": ..., "lambdas": [...]}
"""
import json
import os
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


def scalar(block_text, key):
    if not block_text:
        return None
    m = re.search(r'(?m)^\s*"?' + re.escape(key) + r'"?\s*=\s*"([^"]*)"', block_text)
    return m.group(1) if m else None


def main():
    path, region, project = sys.argv[1], sys.argv[2], sys.argv[3]
    text = open(path).read()

    harness_block = find_block(text, "harness")
    aws_connector_id = scalar(harness_block, "aws_connector_id")

    buckets_block = find_block(text, "artifact_buckets")
    bucket = scalar(buckets_block, region)

    lambdas = []
    src_root = os.path.join("lambda-src", project)
    if os.path.isdir(src_root):
        for key in sorted(os.listdir(src_root)):
            if os.path.isdir(os.path.join(src_root, key)):
                lambdas.append(
                    {"key": key, "bucket": bucket, "object_key": f"{project}/{key}/lambda.zip"}
                )

    print(json.dumps({"aws_connector_id": aws_connector_id, "bucket": bucket, "lambdas": lambdas}))


if __name__ == "__main__":
    main()
