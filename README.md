# caldav.rb

A CalDAV client library for Ruby, built on [webdav](https://github.com/thoran/webdav) and implementing RFC 4791. This release ships **Layer 1 (Protocol)** of a planned three-layer ecosystem.


## Installation

```
gem install caldav.rb
```

Or in your Gemfile:

```ruby
gem 'caldav.rb'
```


## Concepts

caldav.rb is designed in three layers, each a strict superset of the one below. This release ships Layer 1 only; the higher layers are future releases with reserved require paths.

- **Layer 1 — Protocol** (this release). The CalDAV verbs, multistatus responses, and namespace-aware navigation accessors. The equivalent of a raw protocol library: it returns CalDAV-typed responses but does not parse iCalendar payloads or construct domain objects. Most users will want Layer 2 once it ships; until then, the protocol layer is usable directly by reading `resource.calendar_data` and parsing it with the `icalendar` gem.
- **Layer 2 — Objects** (future, `require 'caldav.rb/objects'`). `CalDAV::Event`, `CalDAV::Calendar`, and `CalDAV::Principal` value objects with iCalendar parsing and convenience predicates.
- **Layer 3 — Queryable** (future, `require 'caldav.rb/queryable'`). A [Namo](https://github.com/thoran/namo)-backed `CalDAV::Query::Calendar` exposing events as queryable rows with derived columns.


## Usage

```ruby
require 'caldav.rb'

caldav = CalDAV.new('https://caldav.example.com/dav/', username: 'user', password: 'pass')
```

### Discovery

```ruby
principal = caldav.current_user_principal
home = caldav.calendar_home_set(principal)
caldav.calendars(home).each{|href| puts href}
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

### Protocol verbs (RFC 4791)

- `mkcalendar(path, body:)` — §5.3.1. Create a calendar collection. Returns a `WebDAV::Response`.
- `calendar_query(path, body:, depth:)` — §7.8. REPORT with a `<c:calendar-query>` body. Returns a `CalDAV::MultiStatus`.
- `calendar_multiget(path, body:, depth:)` — §7.9. REPORT with a `<c:calendar-multiget>` body. Returns a `CalDAV::MultiStatus`.
- `freebusy_query(path, body:, depth:)` — §7.10. REPORT with a `<c:free-busy-query>` body. Returns a raw `WebDAV::Response` carrying VFREEBUSY iCalendar data — **not** a multistatus. This asymmetry is inherent to the CalDAV spec.

### Discovery

- `current_user_principal(path = base URL path)` — returns the principal URL string. PROPFINDs the base URL's path by default; pass a path to start discovery elsewhere.
- `calendar_home_set(principal = current_user_principal)` — returns the calendar-home-set URL string.
- `calendars(home = calendar_home_set)` — returns an array of calendar collection URL strings.


## Responses

The REPORT verbs return `CalDAV::MultiStatus`, a type-preserving subclass of `WebDAV::MultiStatus` whose `resources` are `CalDAV::Resource` objects. Each `CalDAV::Resource` adds CalDAV-namespace navigation accessors over the underlying webdav resource:

- `href` — the resource URL
- `calendar_data` — the iCalendar string from `<c:calendar-data>`
- `calendar_description` — `<c:calendar-description>`
- `supported_calendar_component_set` — `<c:supported-calendar-component-set>`
- `calendar_timezone` — the VTIMEZONE string from `<c:calendar-timezone>`
- `is_calendar?` — true when `<d:resourcetype>` includes `<c:calendar/>`

These are strictly navigation: they return raw strings and values, never parsed iCalendar objects. Parsing is Layer 2's job.


## Limitations

This is a Layer 1 protocol release. Known boundaries:

- **Read-only.** Conditional writes need `If-Match`, which webdav's `put` does not yet expose; writes arrive with Layer 2.
- **No iCalendar parsing.** Use the `icalendar` gem on `resource.calendar_data` if you need parsed events now.
- **Basic auth only.** No OAuth.
- **Tested against one real CalDAV server.** Other servers should work but are unverified.
- **No sync-collection.** Incremental sync is deferred.


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
