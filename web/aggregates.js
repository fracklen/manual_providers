{
  "size": 100,
  "query": {
    "bool": {
      "should": [
        { "match": { "address": "Nærum"}},
        { "match": { "description": "Nærum"}}
        { "bool":  {
          "must": [
            { "match": { "state": "active" }}
          ]
        }}
      ]
    }
  },
  "highlight": {
    "pre_tags": ["<mark>"],
    "post_tags": ["</mark>"],
    "fields": { "description": { "fragment_size": 1000 }, "address": { "fragment_size": 1000 } }
  }
}



{
  "size": 100,
  "query": {
    "bool": {
      "should": [
        { "match": { "address": "Nærum"}},
        { "match": { "description": "Nærum"}},
        { "bool":  {
          "must": [
            { "match": { "state": "active" }}
          ]
        }}
      ]
    }
  },
  "highlight": {
    "pre_tags": ["<mark>"],
    "post_tags": ["</mark>"],
    "fields": { "description": { "fragment_size": 1000 }, "address": { "fragment_size": 1000 } }
  }
}
