
## Storm Crawler Documentation

- ### crawler-conf.yaml
```
config: 
  topology.workers: 1
  topology.message.timeout.secs: 300
  topology.max.spout.pending: 100
  topology.debug: false

  fetcher.threads.number: 50
  
  # give 2gb to the workers
  worker.heap.memory.mb: 2048

  # mandatory when using Flux
  topology.kryo.register:
    - com.digitalpebble.stormcrawler.Metadata

  # metadata to transfer to the outlinks
  # used by Fetcher for redirections, sitemapparser, etc...
  # these are also persisted for the parent document (see below)
  # metadata.transfer:
  # - customMetadataName

  # lists the metadata to persist to storage
  # these are not transfered to the outlinks
  metadata.persist:
   - _redirTo
   - error.cause
   - error.source
   - isSitemap
   - isFeed

  http.agent.name: "Anonymous Coward"
  http.agent.version: "1.0"
  http.agent.description: "built with StormCrawler Archetype 1.13"
  http.agent.url: "http://someorganization.com/"
  http.agent.email: "someone@someorganization.com"

  # The maximum number of bytes for returned HTTP response bodies.
  # The fetched page will be trimmed to 65KB in this case
  # Set -1 to disable the limit.
  http.content.limit: -1
  jsoup.treat.non.html.as.error: false

  # FetcherBolt queue dump => comment out to activate
  # if a file exists on the worker machine with the corresponding port number
  # the FetcherBolt will log the content of its internal queues to the logs
  # fetcherbolt.queue.debug.filepath: "/tmp/fetcher-dump-{port}"

  parsefilters.config.file: "parsefilters.json"
  urlfilters.config.file: "urlfilters.json"

  # revisit a page daily (value in minutes)
  # set it to -1 to never refetch a page
  fetchInterval.default: 1440

  # revisit a page with a fetch error after 2 hours (value in minutes)
  # set it to -1 to never refetch a page
  fetchInterval.fetch.error: 120

  # never revisit a page with an error (or set a value in minutes)
  fetchInterval.error: -1

  # text extraction for JSoupParserBolt
  textextractor.include.pattern:
   - DIV[id="maincontent"]
   - DIV[itemprop="articleBody"]
   - ARTICLE

  textextractor.exclude.tags:
   - STYLE
   - SCRIPT

  # custom fetch interval to be used when a document has the key/value in its metadata
  # and has been fetched successfully (value in minutes)
  # fetchInterval.FETCH_ERROR.isFeed=true: 30
  # fetchInterval.isFeed=true: 10

  # configuration for the classes extending AbstractIndexerBolt
  # indexer.md.filter: "someKey=aValue"
  indexer.url.fieldname: "url"
  indexer.text.fieldname: "content"
  indexer.canonical.name: "canonical"
  indexer.md.mapping:
  - parse.title=title
  - parse.keywords=keywords
  - parse.description=description
  - domain=domain
  - seed=seed

  # Metrics consumers:
  topology.metrics.consumer.register:
     - class: "org.apache.storm.metric.LoggingMetricsConsumer"
       parallelism.hint: 1
```
- ### es-crawler.flux
```
name: "Crawler"

includes:
    - resource: true
      file: "/crawler-default.yaml"
      override: false

    - resource: false
      file: "crawler-conf.yaml"
      override: true

    - resource: false
      file: "es-conf.yaml"
      override: true

spouts:
  - id: "spout"
    className: "com.digitalpebble.stormcrawler.elasticsearch.persistence.AggregationSpout"
    parallelism: 10

bolts:
  - id: "partitioner"
    className: "com.digitalpebble.stormcrawler.bolt.URLPartitionerBolt"
    parallelism: 1
  - id: "fetcher"
    className: "com.digitalpebble.stormcrawler.bolt.FetcherBolt"
    parallelism: 1
  - id: "sitemap"
    className: "com.digitalpebble.stormcrawler.bolt.SiteMapParserBolt"
    parallelism: 1
  - id: "parse"
    className: "com.digitalpebble.stormcrawler.bolt.JSoupParserBolt"
    parallelism: 1
  - id: "index"
    className: "com.digitalpebble.stormcrawler.elasticsearch.bolt.IndexerBolt"
    parallelism: 1
  - id: "status"
    className: "com.digitalpebble.stormcrawler.elasticsearch.persistence.StatusUpdaterBolt"
    parallelism: 1
  - id: "status_metrics"
    className: "com.digitalpebble.stormcrawler.elasticsearch.metrics.StatusMetricsBolt"
    parallelism: 1
  - id: "redirection_bolt"
    className: "com.digitalpebble.stormcrawler.tika.RedirectionBolt"
    parallelism: 1
  - id: "parser_bolt"
    className: "com.digitalpebble.stormcrawler.tika.ParserBolt"
    parallelism: 1 

streams:
  - from: "spout"
    to: "partitioner"
    grouping:
      type: SHUFFLE
      
  - from: "spout"
    to: "status_metrics"
    grouping:
      type: SHUFFLE     

  - from: "partitioner"
    to: "fetcher"
    grouping:
      type: FIELDS
      args: ["key"]

  - from: "fetcher"
    to: "sitemap"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "sitemap"
    to: "parse"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "parse"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "fetcher"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "sitemap"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "parse"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"

  - from: "index"
    to: "status"
    grouping:
      type: FIELDS
      args: ["url"]
      streamId: "status"
  - from: "parse"
    to: "redirection_bolt"
    grouping:
      type: LOCAL_OR_SHUFFLE


  - from: "redirection_bolt"
    to: "parser_bolt"
    grouping:
      type: LOCAL_OR_SHUFFLE


  - from: "redirection_bolt"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE


  - from: "parser_bolt"
    to: "index"
    grouping:
      type: LOCAL_OR_SHUFFLE

  - from: "redirection_bolt"
    to: "parser_bolt"
    grouping:
      type: LOCAL_OR_SHUFFLE
      streamId: "tika"
```
- ### es-conf.yaml
```
# configuration for Elasticsearch resources
  
config:
  # ES indexer bolt
  # adresses can be specified as a full URL
  # if not we assume that the protocol is http and the port 9200
  es.indexer.addresses: "https://elasticserver:9271"
  es.indexer.index.name: "index"
  # es.indexer.pipeline: "_PIPELINE_"
  es.indexer.doc.type: "doc"
  es.status.user: "USERNAME"
  es.status.password: "PASSWORD"
  es.indexer.create: false
  es.indexer.settings:
    cluster.name: "rit-web"
  
  # ES metricsConsumer
  es.metrics.addresses: "https://elasticserver:9271"
  es.metrics.index.name: "metrics"
  es.metrics.doc.type: "datapoint"
  es.status.user: "USERNAME"
  es.status.password: "PASSWORD"
  es.metrics.settings:
    cluster.name: "rit-web"
  
  # ES spout and persistence bolt
  es.status.addresses: "https://elasticserver:9271"
  es.status.index.name: "status"
  es.status.doc.type: "status"
  es.status.user: "USERNAME"
  es.status.password: "PASSWORD"
  # the routing is done on the value of 'partition.url.mode'
  es.status.routing: true
  # stores the value used for the routing as a separate field
  # needed by the spout implementations
  es.status.routing.fieldname: "metadata.hostname"
  es.status.bulkActions: 500
  es.status.flushInterval: "5s"
  es.status.concurrentRequests: 1
  es.status.settings:
    cluster.name: "rit-web"
  
  ################
  # spout config #
  ################
  
  # positive or negative filter parsable by the Lucene Query Parser
  # es.status.filterQuery: "-(metadata.hostname:stormcrawler.net)"

  # time in secs for which the URLs will be considered for fetching after a ack of fail
  spout.ttl.purgatory: 30
  
  # Min time (in msecs) to allow between 2 successive queries to ES
  spout.min.delay.queries: 500

  # Delay since previous query date (in secs) after which the nextFetchDate value will be reset to the current time
  # Setting this to -1 or a large value means that the ES will cache the results but also that less and less results
  # might be returned.
  spout.reset.fetchdate.after: 120

  es.status.max.buckets: 50
  es.status.max.urls.per.bucket: 15
  # field to group the URLs into buckets
  es.status.bucket.field: "metadata.hostname"
  # field to sort the URLs within a bucket
  es.status.bucket.sort.field: "nextFetchDate"
  # field to sort the buckets
  es.status.global.sort.field: "nextFetchDate"

  # CollapsingSpout : limits the deep paging by resetting the start offset for the ES query 
  es.status.max.start.offset: 500
  
  # AggregationSpout : sampling improves the performance on large crawls
  es.status.sample: false

  # AggregationSpout (expert): adds this value in mins to the latest date returned in the results and
  # use it as nextFetchDate
  es.status.recentDate.increase: -1
  es.status.recentDate.min.gap: -1

  topology.metrics.consumer.register:
       - class: "com.digitalpebble.stormcrawler.elasticsearch.metrics.MetricsConsumer"
         parallelism.hint: 1
         #whitelist:
         #  - "fetcher_counter"
         #  - "fetcher_average.bytes_fetched"
         #blacklist:
         #  - "__receive.*"
```
