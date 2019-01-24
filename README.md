# INDEX CONFIGURATION 
Index configuration includes
  - Stemming
  - synonyms
  - stopwords
  - Snowball

## Main Index & Mapping
```PUT index
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
            },
            "seed":{
               "type":"keyword",
               "index":"true",
               "store":true
            }
         }
      }
   }
}
```
**Note:** By Default elastic search able to search 10,000 documents. We need to change the max result limit inorder to fetch the results more than 10,000 and likewise change the max rescore to the result same as results limit.
```
PUT index/_settings
{
  "index.max_result_window" : "10000000",
  "max_rescore_window": "10000000"
}
```

## Status Index & Mapping
```
{
    "settings": {
        "index": {
            "number_of_shards": 10,
            "number_of_replicas": 0,
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
}
```
## Metrics Index & Mapping
```
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
```
### Stemmer Analyzer 
This analyzer is used to search the stem words if the exact words cannot find in the index. If you want to search for the keyword **"hike"** and you dont have exact match word in the index the stemmer come into place and fetch the results includes  **"hiking"**.  We are using 'English' language as our default one.

### Snowball Analyzer
This analyzer is used to soleve the problem of singular and plural tenses. This analyzer will give the results  regardless of whether we entered **"admission"** or **"admissions"** otherwise the elastic search consider those as different words. 

### Stop Analyzer
This analyzer is used mainly to remove the conjunctions (e.g:and,at,in ,but, etc.,) from the search inorder to increase the efficiency of the search and this analyzers helps to remove the illegal terms based on the request (e.g: restrict the term **"skating"** to search). 

### Synonyms Analyzer
This analyzer is used to increase the flexibility of search With minimal configuration. Suppose we want to search a keyword "center for computational relativity and gravitation", it looks bit weired and lazy to type this huge keyword and we are defining this keyword as **"ccrg"**. If you enter **"ccrg"** the results related to **"center for computational relativity and gravitation"** will get diplayed. 

### Whitespace Analyzer
The whitespace analyzer breaks text into terms whenever it encounters a whitespace character.

Consider the text: ```A new generation of advanced ground-based and space-borne telescopes.``` 

Whitespace analyzer: ```A, new, generation, of, advanced, ground-based, and, space-borne, telescopes.```

Standard analyzer: ```A, new, generation, of, advanced, ground, based, and, space, borne, telescopes```


### Deleting the results 

To delete the records  consider the below indexes main-index & status-index
- Deleting the records by Url with wildcards

```
POST www-some-index/_delete_by_query {
   "query":{
      "wildcard":{
         "url":{
            "value":"https://www.some.edu/apply/about*"
         }
      }
   }
}
```

- main-index results
```
_index: "main-index",
_type: "doc",
_id: "689251e67ed7b7071fbf4196a805cb3fe60d2322e5feaf95baf1f5f5888c86f6",
_score: 10.67163,
_source: {
content: "Bachelor's Brochure | Master's Brochure   The University offers quality American bachelor and master's degrees in business, leadership, computing and engineering, that teach and practice global intelligence and provide you with relevant work experience through our cooperative education program that will make you stand out in the competitive job market. In today’s technological oriented world, engineering and computing skills are highly sought after by all kinds of businesses, and the opportunities for professional success are limitless. Kate Gleason College of Engineering and B. Thomas Golisano College of Computing and Information Sciences in New York have outstanding record of producing graduates who are well versed in all aspects of current engineering and computing practices. You will be prepared to lead technical innovation and develop next-generation products and processes, and be ready for the challenges of your profession.",
url: "https://www.test.edu/college/academics/degreeprograms",
domain: "test.edu",
description: [],
title: []
```

- status-index results
```
{
_index: "status-index",
_type: "status",
_id: "689251e67ed7b7071fbf4196a805cb3fe60d2322e5feaf95baf1f5f5888c86f6",
_score: 1,
_routing: "www.test.edu",
_source: {
url: "https://www.test.edu/college/academics/degreeprograms",
status: "FETCHED",
metadata: {
url%2Epath: [
"https://www.test.edu/college",
"https://www.test.edu/college/"
],
depth: [
"2"
],
hostname: "www.test.edu"
},
nextFetchDate: "2019-01-08T19:05:18.000Z"
}
},
```
In order to delete the results from the index choose the desired result id of the generated results and delete by using that id by running the DELETE API

```
DELETE /main-index/doc/689251e67ed7b7071fbf4196a805cb3fe60d2322e5feaf95baf1f5f5888c86f6
```

Delete the same result as well as in the status-index. You will find same match id in the status-index. If you won't delete in the status-index there may be a chances that crawler refetch that page and index into the main-index

```
DELETE /status-index/status/689251e67ed7b7071fbf4196a805cb3fe60d2322e5feaf95baf1f5f5888c86f6
```

### Deleting the indexes
Let say if we have three indexes main-index, main-status, main-metrics. Delete all indexes by appling  wildcards rather than delteing individual indices.   
```
DELETE main-*
{
  
}
```

### Tip:

- When creating the status index make sure that the refresh interval value match with the crawler **spout.min.delay.queries** value.

  **E.g.** 
```
Status-Index      Index Refresh Interval      spout.min.delay.queries
www-colleges        0.5s (500ms)                  500ms
www-all             1s                            1000ms       
www-archives        2s                            2000ms
non-public          1.5s (1500ms)                 1500ms	
```

## Useful Queries

- Get Results by wildcards
```
POST www-newindex-index/_search
{  
  "size":30,
   "query":{  
      "bool":{  
         "must":[  
            {   "wildcard":{
                 "url":{
                 "value":"http://www.some.edu/college1/staff/*"
               }}
            }
         ]
      }
   }
}
```
## References

- https://www.elastic.co
- https://qbox.io/blog


Still need to update...
