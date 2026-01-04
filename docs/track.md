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
      "track_guid": "{A568F9F6-1A9F-4823-9D8E-D3A2FAC56B94}",
      "created": true,
      "track_index": 15,
      "track_name": "piano"
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

## track.rename

param:

-   index: int
-   name: str

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
    "func": "track.rename",
    "param": {
      "index": 0,
      "name": "electric_guitar"
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
    "func": "track.rename",
    "param": {
      "index": 0,
      "name": "electric_guitar"
    }
  },
  "response": {
    "ok": true,
    "result": {
      "track_index": 0,
      "track_name": "electric_guitar",
      "renamed": true
    },
    "error": null
  }
}
```

## track.set_color

param:

-   index: int
-   color: int

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
    "func": "track.set_color",
    "param": {
      "index": 0,
      "color": [255,0,0]
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
    "func": "track.set_color",
    "param": {
      "index": 0,
      "color": [255,0,0]
    }
  },
  "response": {
    "ok": true,
    "result": {
      "track_index": 0,
      "color": [255,0,0],
      "set_color": true
    },
    "error": null
  }
}
```

## track.get_color

param:

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
    "func": "track.get_color",
    "param": {
      "index": 0
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
    "func": "track.get_color",
    "param": {
      "index": 0
    }
  },
  "response": {
    "ok": true,
    "result": {
      "track_index": 0,
      "color": [255,0,0]
    },
    "error": null
  }
}
```

## project.get_track_count

param: none

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
    "func": "project.get_track_count",
    "param": {}
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
    "func": "project.get_track_count",
    "param": {}
  },
  "response": {
    "ok": true,
    "result": {
      "count": 5
    },
    "error": null
  }
}
```

## project.get_track_list

param: none

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
    "func": "project.get_track_list",
    "param": {}
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
    "func": "project.get_track_list",
    "param": {}
  },
  "response": {
    "ok": true,
    "result": {
      "tracks": [
        {
          "track_index": 0,
          "track_name": "piano",
          "track_guid": "{A568F9F6-1A9F-4823-9D8E-D3A2FAC56B94}",
          "track_color": [255,0,0],
          "is_muted": false,
          "is_soloed": false,
          "is_armed": false,
          "volume": 1.0
        },
        {
          "track_index": 1,
          "track_name": "guitar",
          "track_guid": "{913B8573-BBC7-4FAD-8666-175A48395C1E}",
          "track_color": [0,0,0],
          "is_muted": false,
          "is_soloed": false,
          "is_armed": false,
          "volume": 0.8
        }
      ],
      "count": 2
    },
    "error": null
  }
}
```
