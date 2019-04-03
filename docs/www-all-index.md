## Index Configuration for `www-all-index`
````
PUT www-all-index
{
   "settings":{
      "index":{
         "number_of_shards":4,
         "number_of_replicas":0,
         "refresh_interval":"5s",
         "analysis":{
            "analyzer":{
               "my_analyzer":{
                  "tokenizer":"whitespace",
                  "filter":[
                     "lowercase",
                     "my_snow",
                     "my_stemmer",
                     "my_synonym",
                     "my_stop"
                  ]
               }
            },
            "filter":{
               "my_stop":{
                  "type":"stop",
                  "stopwords_path":"stopwords/stopwords_en.txt"
               },
               "my_snow":{
                  "type":"snowball",
                  "language":"English"
               },
               "my_synonym":{
                  "type":"synonym_graph",
                  "expand":false,
                  "synonyms_path":"analysis/synonym.txt"
               },
               "my_stemmer":{
                  "type":"stemmer",
                  "name":"english"
               }
            }
         }
      }
   },
   "mappings":{
      "doc":{
         "_source":{
            "enabled":true
         },
         "properties":{
            "title":{
               "type":"text",
               "index":"true",
               "store":true,
               "analyzer":"my_analyzer"
            },
            "content":{
               "type":"text",
               "index":"true",
               "store":true,
               "analyzer":"my_analyzer"
            },
            "url":{
               "type":"keyword",
               "index":"true",
               "store":true
            },
            "host":{
               "type":"keyword",
               "index":"true",
               "store":true
            }
         }
      }
   }
} 
````



````
PUT www-all-status
{
    "settings": {
        "index": {
            "number_of_shards": 10,
            "number_of_replicas": 0,
            "refresh_interval": "1s"
        }
    },
    "mappings": {
        "status": {
            "dynamic_templates": [{
                "metadata": {
                    "path_match": "metadata.*",
                    "match_mapping_type": "string",
                    "mapping": {
                        "type": "keyword"
                    }
                }
            }],
            "_source": {
                "enabled": true
            },
            "properties": {
                "nextFetchDate": {
                    "type": "date",
                    "format": "dateOptionalTime"
                },
                "status": {
                    "type": "keyword"
                },
                "url": {
                    "type": "keyword"
                }
            }
        }
    }
}
````





````

PUT www-all-metrics
{
  "template": "metrics*",
  "settings": {
    "index": {
      "number_of_shards": 1,
      "refresh_interval": "30s"
    },
    "number_of_replicas" : 0
  },
  "mappings": {
    "datapoint": {
      "_source":         { "enabled": true },
      "properties": {
          "name": {
            "type": "keyword"
          },
          "srcComponentId": {
            "type": "keyword"
          },
          "srcTaskId": {
            "type": "long"
          },
          "srcWorkerHost": {
            "type": "keyword"
          },
          "srcWorkerPort": {
            "type": "long"
          },
          "timestamp": {
            "type": "date",
            "format": "dateOptionalTime"
          },
          "value": {
            "type": "double"
          }
      }
    }
  }
} 
````

