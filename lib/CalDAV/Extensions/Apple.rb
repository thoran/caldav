# CalDAV/Extensions/Apple.rb
# CalDAV::Extensions::Apple

# The apple calendar-color property. A non-RFC-4791 vendor extension: it prepends
# its namespace and property onto the calendar-discovery request and mixes its
# reader into Resource. Composes with other extensions via super. Loaded with the
# object layer; omitted by 'CalDAV/Objects/Core'.

require_relative '../../caldav'

class CalDAV < WebDAV
  module Extensions
    module Apple
      NAMESPACE = 'http://apple.com/ns/ical/'

      private def calendars_request_namespaces
        %(#{super} xmlns:ic="#{NAMESPACE}")
      end

      private def calendars_request_properties
        "#{super}\n        <ic:calendar-color/>"
      end

      module Reader
        def calendar_color
          property(CalDAV::Extensions::Apple::NAMESPACE, 'calendar-color')
        end
      end
    end
  end

  prepend Extensions::Apple
  Resource.include Extensions::Apple::Reader
end
