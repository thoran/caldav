# test/CalDAV/Resource_test.rb

require_relative '../helper'

describe CalDAV::Resource do
  let(:calendar_xml) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:response>
          <d:href>/calendars/user/work/</d:href>
          <d:propstat>
            <d:prop>
              <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
              <d:displayname>Work</d:displayname>
              <c:calendar-description>Work calendar</c:calendar-description>
              <c:supported-calendar-data><c:calendar-data content-type="text/calendar" version="2.0"/></c:supported-calendar-data>
              <c:max-resource-size>10485760</c:max-resource-size>
              <c:min-date-time>19000101T000000Z</c:min-date-time>
              <c:max-date-time>20491231T235959Z</c:max-date-time>
              <c:max-instances>100</c:max-instances>
              <c:max-attendees-per-instance>25</c:max-attendees-per-instance>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/calendars/user/work/event.ics</d:href>
          <d:propstat>
            <d:prop>
              <d:getetag>"abc123"</d:getetag>
              <c:calendar-data>BEGIN:VCALENDAR</c:calendar-data>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/calendars/user/calendar-proxy-read/</d:href>
          <d:propstat>
            <d:prop>
              <d:resourcetype><d:collection/><cs:calendar-proxy-read xmlns:cs="http://calendarserver.org/ns/"/></d:resourcetype>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
  end

  let(:multistatus){CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: calendar_xml))}
  let(:calendar_resource){multistatus.resources[0]}
  let(:event_resource){multistatus.resources[1]}
  let(:proxy_resource){multistatus.resources[2]}

  it "wraps resources as CalDAV::Resource" do
    _(calendar_resource).must_be_kind_of CalDAV::Resource
  end

  it "exposes href" do
    _(calendar_resource.href).must_equal '/calendars/user/work/'
  end

  it "reads displayname" do
    _(calendar_resource.display_name).must_equal 'Work'
  end

  it "reads calendar-description" do
    _(calendar_resource.calendar_description).must_equal 'Work calendar'
  end

  it "reads calendar-data" do
    _(event_resource.calendar_data).must_equal 'BEGIN:VCALENDAR'
  end

  it "reads supported-calendar-data as serialised markup" do
    _(calendar_resource.supported_calendar_data).must_match %r{<(?:\w+:)?calendar-data\b[^>]*content-type=['"]text/calendar['"][^>]*version=['"]2\.0['"]}
  end

  it "reads max-resource-size" do
    _(calendar_resource.max_resource_size).must_equal '10485760'
  end

  it "reads min-date-time" do
    _(calendar_resource.min_date_time).must_equal '19000101T000000Z'
  end

  it "reads max-date-time" do
    _(calendar_resource.max_date_time).must_equal '20491231T235959Z'
  end

  it "reads max-instances" do
    _(calendar_resource.max_instances).must_equal '100'
  end

  it "reads max-attendees-per-instance" do
    _(calendar_resource.max_attendees_per_instance).must_equal '25'
  end

  it "identifies a calendar collection" do
    _(calendar_resource.is_calendar?).must_equal true
  end

  it "identifies a non-calendar resource" do
    _(event_resource.is_calendar?).must_equal false
  end

  it "does not mistake a calendar-proxy collection for a calendar" do
    _(proxy_resource.is_calendar?).must_equal false
  end

  it "identifies a calendar from a pretty-printed (indented) resourcetype" do
    pretty = CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML))
      <?xml version="1.0" encoding="utf-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:response>
          <d:href>/dav/calendars/user/x/work/</d:href>
          <d:propstat>
            <d:prop>
              <d:resourcetype>
                <d:collection/>
                <c:calendar/>
              </d:resourcetype>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
      </d:multistatus>
    XML
    _(pretty.resources.first.is_calendar?).must_equal true
  end
end
