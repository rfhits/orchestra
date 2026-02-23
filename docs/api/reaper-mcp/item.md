# item 规范

## item.set_color

param:

-   item_guid: str
-   clear: bool（默认 false）
-   color: int[3]（`clear=false` 时必填，RGB）

request.json:

```json
{
  "meta": {
    "version": "1",
    "id": "1732854600007_item_set_color_test",
    "ts_ms": 1732854600007,
    "agent_id": "test"
  },
  "request": {
    "func": "item.set_color",
    "param": {
      "item_guid": "{REPLACE_WITH_ITEM_GUID}",
      "clear": false,
      "color": [255, 0, 0]
    }
  }
}
```

reply success:

```json
{
  "response": {
    "ok": true,
    "result": {
      "item_guid": "{REPLACE_WITH_ITEM_GUID}",
      "has_custom_color": true,
      "rgb": [255, 0, 0],
      "hex": "#FF0000"
    },
    "error": null
  }
}
```

clear color:

```json
{
  "request": {
    "func": "item.set_color",
    "param": {
      "item_guid": "{REPLACE_WITH_ITEM_GUID}",
      "clear": true
    }
  }
}
```

## item.get_color

param:

-   item_guid: str

request.json:

```json
{
  "meta": {
    "version": "1",
    "id": "1732854600008_item_get_color_test",
    "ts_ms": 1732854600008,
    "agent_id": "test"
  },
  "request": {
    "func": "item.get_color",
    "param": {
      "item_guid": "{REPLACE_WITH_ITEM_GUID}"
    }
  }
}
```

reply success:

```json
{
  "response": {
    "ok": true,
    "result": {
      "item_guid": "{REPLACE_WITH_ITEM_GUID}",
      "has_custom_color": true,
      "rgb": [255, 0, 0],
      "hex": "#FF0000"
    },
    "error": null
  }
}
```
