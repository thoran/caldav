# caldav.rb

A CalDAV client library for Ruby, built on [webdav](https://github.com/thoran/webdav) and implementing RFC 4791. It ships **Layer 1 (Protocol)** and the beginning of **Layer 2 (Objects)** — Calendar objects — of a planned three-layer ecosystem.


## Installation

```
gem install caldav.rb
```

Or in your Gemfile:

```ruby
gem 'caldav.rb'
```


## Concepts

caldav.rb is designed in three layers, each a strict superset of the one below. Layer 1 is complete; Layer 2 has begun with Calendar objects; its Event and Principal objects, and all of Layer 3, are future releases.

- **Layer 1 — Protocol.** The CalDAV verbs, multistatus responses, and namespace-aware navigation accessors. The equivalent of a raw protocol library: it returns CalDAV-typed responses but does not parse iCalendar payloads or construct domain objects. For events, read `resource.calendar_data` and parse it with the `icalendar` gem until Layer 2's `CalDAV::Event` lands.
- **Layer 2 — Objects** (`require 'CalDAV/Objects'`). Value objects over the protocol layer. `CalDAV::Calendar` and object-returning discovery (`CalDAV::Calendar.all`) ship now, with vendor properties (getctag, calendar-color) available and separable (`require 'CalDAV/Objects/Core'` to omit them). `CalDAV::Event` (with iCalendar parsing) and `CalDAV::Principal` are still to come.
- **Layer 3 — Queryable** (future, `require 'CalDAV/Queryable'`). A [Namo](https://github.com/thoran/namo)-backed `CalDAV::Query::Calendar` exposing events as queryable rows with derived columns.


## Usage

```ruby
require 'caldav.rb'

caldav = CalDAV.new('https://caldav.example.com/dav/', username: 'user', password: 'pass')
```

The object layer (`require 'CalDAV/Objects'`) is the high-level API; today it covers calendar discovery. Everything else below is the protocol layer it is built on — which you can always use directly for raw access.

### Discovery

With the object layer, listing calendars returns `CalDAV::Calendar` objects — `Calendar.all` walks principal → home-set → calendars for you:

```ruby
require 'CalDAV/Objects'
CalDAV::Calendar.all(client: caldav).each{|calendar| puts calendar.display_name}
```

Each `Calendar` exposes its collection's properties:

```ruby
calendar = CalDAV::Calendar.all(client: caldav).first
calendar.path                  # "/dav/calendars/user/work/"
calendar.description           # the calendar-description string
calendar.timezone              # the raw VTIMEZONE string, if the server sets one
calendar.supported_components  # the raw supported-component-set (unparsed markup)
calendar.ctag                  # change tag for cheap sync-detection (vendor extension)
calendar.color                 # the calendar colour (vendor extension)
calendar.to_s                  # display name, or path when unnamed
```

`ctag` and `color` come from the vendor extensions, loaded by default. Require the core objects instead to omit them — the readers stay, but return `nil`:

```ruby
require 'CalDAV/Objects/Core'  # strictly RFC 4791 — no vendor extensions
CalDAV::Calendar.all(client: caldav).first.ctag   # => nil
```

Drop to the protocol layer when you want the raw resources, or aren't loading the object layer — the same walk, step by step:

```ruby
principal = caldav.current_user_principal
home = caldav.calendar_home_set(principal)
caldav.calendars(home).each{|resource| puts resource.href}  # CalDAV::Resource objects
```

Each discovery helper defaults its argument to the result of the previous step, so `caldav.calendars` alone walks principal → home-set → calendars.

Discovery begins by PROPFINDing the **path of the base URL**. Many servers do not expose the current-user-principal at `/`, so point the base URL at the server's CalDAV context — e.g. `https://caldav.example.com/dav/` rather than `https://caldav.example.com/`. (RFC 6764 `.well-known/caldav` redirects are not auto-followed for PROPFIND in this release.) You can also override the starting point per call: `caldav.current_user_principal('/dav/')`.

### Querying a calendar

```ruby
result = caldav.calendar_query('/calendars/user/work/', body: query_xml)
result.resources.each do |resource|
  puts resource.href
  puts resource.calendar_data  # the raw iCalendar string
end
```

### Fetching specific events

```ruby
result = caldav.calendar_multiget('/calendars/user/work/', body: multiget_xml)
```

### Free/busy

```ruby
response = caldav.freebusy_query('/calendars/user/work/', body: freebusy_xml)
puts response.body  # VFREEBUSY iCalendar data — not a multistatus
```

### Creating a calendar

```ruby
caldav.mkcalendar('/calendars/user/new/', body: mkcalendar_xml)
```


## Methods

### Layer 1 — Protocol (`require 'caldav.rb'`)

Raw CalDAV-typed responses and navigation resources; no domain objects.

#### Protocol verbs (RFC 4791)

- `mkcalendar(path, body:)` — §5.3.1. Create a calendar collection. Returns a `WebDAV::Response`.
- `calendar_query(path, body:, depth:)` — §7.8. REPORT with a `<c:calendar-query>` body. Returns a `CalDAV::MultiStatus`.
- `calendar_multiget(path, body:, depth:)` — §7.9. REPORT with a `<c:calendar-multiget>` body. Returns a `CalDAV::MultiStatus`.
- `freebusy_query(path, body:, depth:)` — §7.10. REPORT with a `<c:free-busy-query>` body. Returns a raw `WebDAV::Response` carrying VFREEBUSY iCalendar data — **not** a multistatus. This asymmetry is inherent to the CalDAV spec.

#### Discovery

- `current_user_principal(path = base URL path)` — returns the principal URL string. PROPFINDs the base URL's path by default; pass a path to start discovery elsewhere.
- `calendar_home_set(principal = current_user_principal)` — returns the calendar-home-set URL string.
- `calendars(home = calendar_home_set)` — returns the calendar-collection `CalDAV::Resource`s.

### Layer 2 — Objects (`require 'CalDAV/Objects'`)

Value objects built over Layer 1. The default require also loads the vendor extensions (`getctag`, `calendar-color`); `require 'CalDAV/Objects/Core'` omits them.

- `CalDAV::Calendar.all(client:, home: nil)` — discovers a home's calendars and returns `CalDAV::Calendar` objects. `home` defaults to the client's discovered calendar-home-set.
- `CalDAV::Calendar.from_resource(resource)` — maps a single `CalDAV::Resource` to a `CalDAV::Calendar`.
- `CalDAV::Calendar` readers — `path`, `display_name`, `description`, `timezone`, `supported_components`, `ctag`, `color`; `ctag` and `color` are `nil` unless the vendor extensions are loaded. `to_s` gives the display name or path.


## Responses

The REPORT verbs return `CalDAV::MultiStatus`, a type-preserving subclass of `WebDAV::MultiStatus` whose `resources` are `CalDAV::Resource` objects. Each `CalDAV::Resource` adds CalDAV-namespace navigation accessors over the underlying webdav resource:

- `href` — the resource URL
- `display_name` — the human-readable name from `<d:displayname>`
- `calendar_data` — the iCalendar string from `<c:calendar-data>`
- `calendar_description` — `<c:calendar-description>`
- `supported_calendar_component_set` — `<c:supported-calendar-component-set>`
- `supported_calendar_data` — `<c:supported-calendar-data>`
- `calendar_timezone` — the VTIMEZONE string from `<c:calendar-timezone>`
- `max_resource_size` — `<c:max-resource-size>`
- `min_date_time` — `<c:min-date-time>`
- `max_date_time` — `<c:max-date-time>`
- `max_instances` — `<c:max-instances>`
- `max_attendees_per_instance` — `<c:max-attendees-per-instance>`
- `is_calendar?` — true when `<d:resourcetype>` includes `<c:calendar/>`

These are strictly navigation: they return raw strings and values, never parsed iCalendar objects. Parsing is Layer 2's job.


## Limitations

The client reads but does not write, and the object layer is only beginning. Known boundaries:

- **Read-only.** No creating, updating or deleting yet — conditional writes need `If-Match`, which webdav's `put` does not yet expose. Writes are a later increment, beyond Layer 2's read-only objects, not part of them.
- **No iCalendar parsing.** Use the `icalendar` gem on `resource.calendar_data` if you need parsed events now, until Layer 2's `CalDAV::Event` lands.
- **Basic auth only.** No OAuth.
- **Tested against one real CalDAV server.** Other servers should work but are unverified.
- **No sync-collection.** `getctag` gives coarse per-collection change-detection now; fine-grained sync-collection (RFC 6578) is deferred.


## Dependencies

- [webdav](https://github.com/thoran/webdav)


## Testing

```
rake
```

Unit tests stub at the request boundary and need no network. A separate set of
integration tests (`test/integration_test.rb`) run against a real CalDAV server
via [VCR](https://github.com/vcr/vcr): they record real interactions into
host- and credential-scrubbed cassettes under `test/cassettes/` on first run, then
replay offline. Without a cassette and without credentials they skip, so the
default suite stays green.

To record against a live account, supply the server and credentials through the
environment and run `rake`:

```
CALDAV_URL='https://your-caldav-host/' \
CALDAV_USERNAME='you@example.com' \
CALDAV_PASSWORD='app-password' \
rake
```

See [test/cassettes/README.md](test/cassettes/README.md) for details.


## Contributing

1. Fork it [https://github.com/thoran/caldav.rb/fork](https://github.com/thoran/caldav.rb/fork)
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new pull request


## Licence

MIT
