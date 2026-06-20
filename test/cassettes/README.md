# VCR cassettes

Recorded HTTP interactions for the integration tests (`test/integration_test.rb`).
Committed cassettes replay offline, so the suite runs without credentials or
network access.

## Recording / re-recording

Provide the server and credentials through the environment (export them, or use
your shell/credential manager — nothing is read from disk). Use an app-specific
password with CalDAV access if your provider offers one:

```
CALDAV_URL='https://your-caldav-host/' \
CALDAV_USERNAME='you@example.com' \
CALDAV_PASSWORD='app-password' \
rake
```

Credentials are on/off by whether `CALDAV_USERNAME` is set. Without it and without
a cassette, the integration tests skip. Record mode is `:once`: a cassette is
recorded only when absent — to refresh one, delete its `.yml` and re-run with
credentials.

## Safety

Cassettes are scrubbed before writing (see `test/vcr_helper.rb`): the real host is
rewritten to `caldav.example.com`, the account id in `/principals/.../<id>/` and
`/calendars/.../<id>/` paths is replaced with `anon`, and the `Authorization`
header, username, and password are replaced with placeholders — so a committed
cassette never names the server, identifies the account, or leaks credentials.
Still review a new cassette before committing to confirm nothing account-specific
remains (the path rewrite covers the common collection/realm/id layout).
