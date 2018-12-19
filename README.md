# INDEX CONFIGURATION 
Index configuration includes
  - Stemming
  - synonyms
  - stopwords
  - Snowball

## Index Mapping
```PUT index
{
   "settings":{
      "index":{
         "number_of_shards":4,
         "number_of_replicas":1,
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
      "_doc":{
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

## References

- https://www.elastic.co
- https://qbox.io/blog


Still need to update...
