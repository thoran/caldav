# test/vcr_helper.rb

require 'uri'
require 'vcr'

EXAMPLE_CALDAV_URL = 'https://caldav.example.com/dav/'
CALDAV_URL = ENV.fetch('CALDAV_URL', EXAMPLE_CALDAV_URL)

# Replaces the account-identifier segment in CalDAV collection paths (e.g.
# /principals/user/<id>/ or /calendars/user/<id>/) with a fixed placeholder, so a
# committed cassette does not expose an account-specific id. The collection name
# after the id (a calendar name, say) is preserved. Covers the common
# collection/realm/id layout; the credential filters still scrub email-style ids.
ACCOUNT_PATH = %r{(/(?:principals|calendars)/[^/]+/)[^/]+/}

def anonymise_account_path(string)
  string&.gsub(ACCOUNT_PATH, '\1anon/')
end

VCR.configure do |config|
  config.cassette_library_dir = File.expand_path('cassettes', __dir__)
  config.hook_into :webmock
  config.filter_sensitive_data(URI(EXAMPLE_CALDAV_URL).host){URI(ENV['CALDAV_URL']).host if ENV['CALDAV_URL']}
  # Basic auth is base64(user:pass), so the credential filters below would not catch it — filter the Authorization header itself too.
  config.filter_sensitive_data('<BASIC_AUTH>'){|interaction| interaction.request.headers['Authorization']&.first}
  config.filter_sensitive_data('<CALDAV_USERNAME>'){ENV['CALDAV_USERNAME']}
  config.filter_sensitive_data('<CALDAV_PASSWORD>'){ENV['CALDAV_PASSWORD']}
  # Anonymise account ids in request URIs and response bodies before writing. The
  # rewrite is self-consistent (the same paths drive the next request), so the
  # anonymised cassette still replays.
  config.before_record do |interaction|
    interaction.request.uri = anonymise_account_path(interaction.request.uri)
    interaction.response.body = anonymise_account_path(interaction.response.body)
  end
end

def caldav_client
  CalDAV.new(
    CALDAV_URL,
    username: ENV.fetch('CALDAV_USERNAME', 'recorded'),
    password: ENV.fetch('CALDAV_PASSWORD', 'recorded')
  )
end

# Records against the real server when credentials are present; replays from the
# committed cassette otherwise. Skips when a real request would be needed but no
# credentials are set, so the suite stays green without an account. To re-record,
# delete the cassette and re-run with credentials.
def with_caldav_cassette(name)
  cassette = File.join(VCR.configuration.cassette_library_dir, "#{name}.yml")
  unless File.exist?(cassette) || ENV['CALDAV_USERNAME']
    raise Minitest::Skip, "no cassette '#{name}.yml' and CALDAV_USERNAME unset; export CALDAV_URL/CALDAV_USERNAME/CALDAV_PASSWORD to record"
  end
  VCR.use_cassette(name){yield}
end
