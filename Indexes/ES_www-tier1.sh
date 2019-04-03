ESHOST="http://localhost:9200"
ESCREDENTIALS="-u elastic:passwordhere"

# deletes and recreates a status index with a bespoke schema

curl $ESCREDENTIALS -s -XDELETE "$ESHOST/www-tier1-status/" >  /dev/null

echo "Deleted www-tier1-status index"

# http://localhost:9200/status/_mapping/status?pretty

echo "Creating www-tier1-status index with mapping"

curl $ESCREDENTIALS -s -XPUT $ESHOST/www-tier1-status -H 'Content-Type: application/json' -d '
{
	"settings": {
		"index": {
			"number_of_shards": 10,
			"number_of_replicas": 1,
			"refresh_interval": "5s"
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
}'

# deletes and recreates a status index with a bespoke schema

curl $ESCREDENTIALS -s -XDELETE "$ESHOST/www-tier1-metrics/" >  /dev/null

echo ""
echo "Deleted www-tier1-metrics index"

echo "Creating www-tier1-metrics index with mapping"

# http://localhost:9200/metrics/_mapping/status?pretty
curl $ESCREDENTIALS -s -XPUT $ESHOST/www-tier1-metrics -H 'Content-Type: application/json' -d '
{
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
}'

# deletes and recreates a doc index with a bespoke schema

curl $ESCREDENTIALS -s -XDELETE "$ESHOST/www-tier1-index*/" >  /dev/null

echo ""
echo "Deleted www-tier1-index"

echo "Creating www-tier1-index with mapping"

curl $ESCREDENTIALS -s -XPUT $ESHOST/www-tier1-index -H 'Content-Type: application/json' -d '
{
   "settings":{
      "index":{
         "number_of_shards":4,
         "number_of_replicas":0,
         "refresh_interval":"500ms",
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
}'

