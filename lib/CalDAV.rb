# CalDAV.rb
# CalDAV

require 'webdav'

require_relative './CalDAV/Resource'
require_relative './CalDAV/MultiStatus'
require_relative './Net/HTTP/Mkcalendar'

class CalDAV < WebDAV
  NAMESPACE = 'urn:ietf:params:xml:ns:caldav'
  DAV_NAMESPACE = 'DAV:'

  # Protocol verbs (RFC 4791)

  # RFC 4791 §5.3.1. Creates a calendar collection.
  def mkcalendar(path, body: nil)
    response = request(:mkcalendar, path, body: body)
    handle_response(response)
  end

  # RFC 4791 §7.8. REPORT with a <c:calendar-query> body.
  def calendar_query(path, body:, depth: '1')
    report_as_caldav(path, body: body, depth: depth)
  end

  # RFC 4791 §7.9. REPORT with a <c:calendar-multiget> body.
  def calendar_multiget(path, body:, depth: '0')
    report_as_caldav(path, body: body, depth: depth)
  end

  # RFC 4791 §7.10. REPORT with a <c:free-busy-query> body. Asymmetric: returns
  # the raw response carrying iCalendar VFREEBUSY data, not a multistatus.
  def freebusy_query(path, body:, depth: '0')
    response = request(:report, path, body: body, headers: {'Depth' => depth})
    handle_response(response)
  end

  # Discovery helpers. Return paths/strings. And object-oriented discovery API
  # (Principal/Calendar objects) is is planned.

  def current_user_principal(path = discovery_path)
    resource = propfind_as_caldav(path, body: current_user_principal_body, depth: '0').resources.first
    resource&.then{|r| href_property(r, DAV_NAMESPACE, 'current-user-principal')}
  end

  def calendar_home_set(principal = current_user_principal)
    resource = propfind_as_caldav(principal, body: calendar_home_set_body, depth: '0').resources.first
    resource&.then{|r| href_property(r, NAMESPACE, 'calendar-home-set')}
  end

  def calendars(home = calendar_home_set)
    resources = propfind_as_caldav(home, body: calendars_body, depth: '1').resources
    resources.select{|resource| resource.is_calendar?}.collect{|resource| resource.href}
  end

  private

  # Send a REPORT and return the CalDAV-typed multistatus rather than the plain
  # WebDAV one. Constructed from the raw response so the CalDAV resource wrappers
  # are produced by CalDAV::MultiStatus's overridden parse_response.
  def report_as_caldav(path, body:, depth:)
    response = request(:report, path, body: body, headers: {'Depth' => depth})
    raise WebDAV::Error.new(response) if response.code.to_i >= 400
    CalDAV::MultiStatus.new(response)
  end

  # As report_as_caldav, but for PROPFIND. Needed because the inherited #propfind
  # returns a plain WebDAV::MultiStatus whose resources are bare hashes, not
  # CalDAV::Resource wrappers. Discovery relies on the wrappers (#is_calendar?,
  # #href), so it routes through here.
  def propfind_as_caldav(path, body:, depth:)
    response = request(:propfind, path, body: body, headers: {'Depth' => depth})
    raise WebDAV::Error.new(response) if response.code.to_i >= 400
    CalDAV::MultiStatus.new(response)
  end

  # The discovery properties (current-user-principal, calendar-home-set) wrap
  # their value in a nested <d:href>. webdav 0.2.0 renders a nested-element
  # property as serialised markup, so the bare URL is lifted back out here.
  # Caveat: when a server pretty-prints, webdav's `text || to_s` returns the
  # leading whitespace text node and the href is lost upstream; recovering that
  # waits for the webdav-objectifies-resources rework.
  def href_property(resource, namespace, name)
    resource.propstats.each do |propstat|
      href = extract_href(propstat[:properties].dig(namespace, name))
      return href if href
    end
    nil
  end

  def extract_href(value)
    return nil unless value
    match = value.match(%r{<(?:\w+:)?href[^>]*>(.*?)</(?:\w+:)?href>}m)
    href = (match ? match[1] : value).strip
    href.empty? ? nil : href
  end

  # Discovery starts from the path of the configured base URL, so a server that
  # does not expose the current-user-principal at '/' is reached by giving its
  # CalDAV context path in the base URL (e.g. https://host/dav/). Falls back to
  # '/' when the base URL has no path.
  def discovery_path
    @uri.path.empty? ? '/' : @uri.path
  end

  def current_user_principal_body
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:propfind xmlns:d="DAV:">
        <d:prop><d:current-user-principal/></d:prop>
      </d:propfind>
    XML
  end

  def calendar_home_set_body
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:propfind xmlns:d="DAV:" xmlns:c="#{NAMESPACE}">
        <d:prop><c:calendar-home-set/></d:prop>
      </d:propfind>
    XML
  end

  def calendars_body
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:propfind xmlns:d="DAV:">
        <d:prop>
          <d:resourcetype/>
        </d:prop>
      </d:propfind>
    XML
  end
end
