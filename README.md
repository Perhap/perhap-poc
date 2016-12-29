# perhap

perhap is an event store described within a domain driven design and functional programming context.

## How it works

perhap is strictly an immutable event store. It accepts new events, and responds to queries about existing events.

Events are immutable, organized hierarchically using the following structure:

* Realm
  * Domain
    * Aggregate root / Entity
      * Event type
        * Event

### New events

Any event can be added using arbitrary data at all levels, i.e. a user of the event store may record an event of a new type, for a new entity, even for a new domain, without first creating the domain, entity, or event type.

The API for adding an event over HTTP is to post event data to a URL specifying the domain, event type, and entity.

`curl -X POST https://perhap-server/[realm]/[domain]/[entity]/[event_type] -d '{"event": [event data]}'`

Example:

`curl -X POST https://perhap-server/performance/communications/59535c06-79c4-4499-bfcc-c695aaebf491/click -d '{"event": {"URI": "http://..."}}'`

status codes...

### Querying

Querying events follows the same hierarchy as creating new events, but uses a GET instead of a POST. The portion of the hierarchy that is included in the request indicates the scope of the data returned. Some query strings are provided to limit the results within a given scope.

Retrieving events:

* Retrieve all events for a given entity: `curl -X GET https://perhap-server/[realm]/[domain]/[entity]`
* Retrieve a specific event: `curl -X GET https://perhap-server/[realm]/[domain]/[event-id]`
* Retrieve all events within a given domain: `curl -X GET https://perhap-server/[realm]/[domain]`

Retrieving lists of keys:

* List all domains: `curl -X GET https://perhap-server/[realm]/keys`
* List all entities within a domain: `curl -X GET https://perhap-server/[realm]/[domain]/keys`

Filtering results:

* Retrieve all events occuring after a known event: `curl -X GET https://perhap-server/[realm]/[domain]/[entity]?following=[event-id]`

status codes...

streaming...
