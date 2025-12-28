# track 规范

## track.create

param:

-   name: str
-   index: int

request.json:

```json
{
  "meta": {
    "version": "1",
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "track.create",
    "param": {
      "name": "piano",
      "index": -1
    }
  }
}
```

reply success:

```json
{
  "meta": {
    "version": "1",
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "track.create",
    "param": {
      "name": "piano",
      "index": -1
    }
  },
  "response": {
    "ok": true,
    "result": {
    },
    "error": null
  }
}
```

reply failed

```json
{
  "meta": {
    "version": "1",
    "id": "1732854000000_claude_7f3a9c1d2e4b6a8f",
    "ts_ms": 1732854000000,
    "agent_id": "claude"
  },
  "request": {
    "func": "track.create",
    "param": {
      "name": "piano",
      "index": -1
    }
  },
  "response": {
    "ok": false,
    "result": null,
    "error": {
      "code": "unknown_error",
    }
  }
}

```
