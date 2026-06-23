# CalDAV/Resource.rb
# CalDAV::Resource

require 'webdav'

class CalDAV < WebDAV
  class Resource
    attr_reader :hash

    def href
      hash[:href]
    end

    def status
      hash[:status]
    end

    def propstats
      hash[:propstats]
    end

    # Navigation accessors. Strictly navigation, not parsing: they return the
    # underlying iCalendar string or value.

    def calendar_data
      property(NAMESPACE, 'calendar-data')
    end

    def calendar_description
      property(NAMESPACE, 'calendar-description')
    end

    def supported_calendar_component_set
      property(NAMESPACE, 'supported-calendar-component-set')
    end

    def supported_calendar_data
      property(NAMESPACE, 'supported-calendar-data')
    end

    def calendar_timezone
      property(NAMESPACE, 'calendar-timezone')
    end

    def max_resource_size
      property(NAMESPACE, 'max-resource-size')
    end

    def min_date_time
      property(NAMESPACE, 'min-date-time')
    end

    def max_date_time
      property(NAMESPACE, 'max-date-time')
    end

    def max_instances
      property(NAMESPACE, 'max-instances')
    end

    def max_attendees_per_instance
      property(NAMESPACE, 'max-attendees-per-instance')
    end

    # Matches a <calendar> element (under any namespace prefix) in the serialised
    # resourcetype, rather than a bare 'calendar' substring: the substring also
    # matches calendar-proxy-read/write collections, which are not calendars.
    def is_calendar?
      resource_type.match?(%r{<(?:\w+:)?calendar(?:\s[^>]*)?/?>})
    end

    private

    def initialize(hash)
      @hash = hash
    end

    def properties
      @properties ||= propstats.each_with_object({}) do |propstat, result|
        result.merge!(propstat[:properties])
      end
    end

    def property(namespace, name)
      properties.dig(namespace, name)
    end

    def resource_type
      property(DAV_NAMESPACE, 'resourcetype').to_s
    end
  end
end
