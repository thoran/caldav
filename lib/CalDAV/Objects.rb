# CalDAV/Objects.rb
# CalDAV Objects layer (Layer 2), default: with vendor extensions

# Value objects built over the Layer 1 protocol/navigation surface. Opt-in via
# `require 'CalDAV/Objects'`. This default form also loads the vendor extensions
# (calendarserver getctag, apple calendar-color); require 'CalDAV/Objects/Core'
# for the objects without them, a strictly RFC 4791 consumer.

require_relative './Objects/Core'
require_relative './Extensions/Apple'
require_relative './Extensions/CalendarServer'
