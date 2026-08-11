# CalDAV/Extensions/CalendarServer.rb
# CalDAV::Extensions::CalendarServer

# The calendarserver getctag property (calendar-collection sync token). A
# non-RFC-4791 vendor extension: it prepends its namespace and property onto the
# calendar-discovery request and mixes its reader into Resource. Composes with
# other extensions via super. Loaded with the object layer; omitted by
# 'CalDAV/Objects/Core'.

require_relative '../../caldav'

class CalDAV < WebDAV
  module Extensions
    module CalendarServer
      NAMESPACE = 'http://calendarserver.org/ns/'

      private def calendars_request_namespaces
        %(#{super} xmlns:cs="#{NAMESPACE}")
      end

      private def calendars_request_properties
        "#{super}\n        <cs:getctag/>"
      end

      module Reader
        def getctag
          property(CalDAV::Extensions::CalendarServer::NAMESPACE, 'getctag')
        end
      end
    end
  end

  prepend Extensions::CalendarServer
  Resource.include Extensions::CalendarServer::Reader
end
