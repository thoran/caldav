# CalDAV/Calendar.rb
# CalDAV::Calendar

require 'webdav'

class CalDAV < WebDAV
  class Calendar
    attr_reader\
      :path,
      :display_name,
      :ctag,
      :color,
      :description,
      :timezone,
      :supported_components

    class << self
      # Discovers the calendars in a home collection and returns them as
      # Calendars — the high-level, object-returning entry point. The CalDAV
      # client stays the low-level path for anyone wanting the raw resources.
      # home defaults to the client's discovered calendar-home-set.
      def all(client:, home: nil)
        load(client: client, home: home)
      end

      # Builds a Calendar from a CalDAV::Resource (as returned by a calendar-home
      # PROPFIND). Strictly a mapping over the resource's navigation accessors — no
      # parsing. ctag and color are read opportunistically: populated only when
      # the extension accessors are loaded (require 'CalDAV/Objects' pulls them
      # in; 'CalDAV/Objects/Core' does not), and nil otherwise.
      def from_resource(resource)
        new(
          path: resource.href,
          display_name: resource.display_name,
          ctag: (resource.getctag if resource.respond_to?(:getctag)),
          color: (resource.calendar_color if resource.respond_to?(:calendar_color)),
          description: resource.calendar_description,
          timezone: resource.calendar_timezone,
          supported_components: resource.supported_calendar_component_set
        )
      end

      private

      def load(client:, home: nil)
        resources = home ? client.calendars(home) : client.calendars
        resources.collect{|resource| from_resource(resource)}
      end
    end

    def to_s
      display_name || path
    end

    private

    def initialize(path:, display_name: nil, ctag: nil, color: nil, description: nil, timezone: nil, supported_components: nil)
      @path = path
      @display_name = display_name
      @ctag = ctag
      @color = color
      @description = description
      @timezone = timezone
      @supported_components = supported_components
    end
  end
end
