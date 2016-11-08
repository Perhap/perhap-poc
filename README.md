# perhap

perhap is an event store described within a domain driven design and functional programming context.

## How it works

perhap is strictly an immutable event store. It accepts new events, and responds to queries about existing events.

### New events

New events are organized hierarchically using the following structure:

  * Domain
    * Event type
      * Aggregate root / Entity
        * Event

Any event can be added using arbitrary data at all levels, i.e. a user of the event store may record an event of a new type, for a new entity, even for a new domain, without first creating the domain, entity, or event type.

The API for adding an event over HTTP is to post event data to a URL specifying the domain, event type, and entity.

`curl -X POST https://perhap-server/[domain]/[event-type]/[entity]/ -d "[event data]"`

Example:

`curl -X POST https://perhap-server/communications/click/59535c06-79c4-4499-bfcc-c695aaebf491 -d '{"URI": "http://..."}'`


status codes...

### Querying

Querying events follows the same hierarchy as creating new events, but uses a GET instead of a POST. The portion of the hierarchy that is included in the request indicates the scope of the data returned. Some query strings are provided to limit the results within a given scope.

Retrieving events:

* Retrieve all events for a given entity: `curl -X GET https://perhap-server/[domain]/[event-type]/[entity]`
* Retrieve all events of a given event type: `curl -X GET https://perhap-server/[domain]/[event-type]`
* Retrieve all events within a given domain: `curl -X GET https://perhap-server/[domain]`
X Retrieve a specific event: `curl -X GET https://perhap-server/[event-id]`

Retrieving lists of keys:

* List entity keys: `curl -X GET https://perhap-server/[domain]/[event-type]/[entity]/keys`
* List event-type keys: `curl -X GET https://perhap-server/[domain]/[event-type]/keys`
* List domain keys: `curl -X GET https://perhap-server/[domain]/keys`

Filtering results:

* Retrieve events occuring after a known event: `?following=[event-id]`
* Retrieve events before a given time: `?before=[unixtime]`
* Retrieve events after a given time: `?after=[unixtime]`
* Retrieve events between two times: `?after=[unixtime]&before=[unixtime]`

status codes...

streaming...
