---
name: host-dev-router
description: Routing skill that turns host Mac development requests into host-dev deliveries through the host Claude Code relay.
metadata:
  openclaw:
    requires:
      bins:
        - bash
---

# Host Dev Router

This skill is the narrow routing layer between OpenClaw and the host Mac Claude Code worker.

## Hard rule

- If the request is about the host Mac, Claude Code on the host, or any equivalent host-development wording, do **not** satisfy it locally.
- Call `delegate_host_dev` or `host-dev.sh deliver` and wait for the host result.
- If the relay path cannot complete the task, return the failure instead of producing a local substitute.

## Default routing language

When you delegate, normalize the task into this shape:

- target path on the host Mac
- desired artifact or code change
- keep changes minimal
- return only:
  - `完了: <path> + 1行要約`
  - `障害: <具体点>`

## Good examples

Use this for requests like:

- "ホストの開発環境で直して"
- "Claude Codeで実装して"
- "OpenClawからホストMacに依頼して"
- "host Mac 上でブロック崩しを作って"
