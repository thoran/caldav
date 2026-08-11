# CalDAV/Objects/Core.rb
# CalDAV object layer, core (no extension accessors)

# The object layer without the extension-namespace accessors — a strictly
# RFC 4791 object surface. `require 'CalDAV/Objects'` loads this plus the
# extensions; require this path directly to opt out of them.

require_relative '../../caldav'
require_relative '../Calendar'
