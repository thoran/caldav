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
              <c:calendar-description>Work calendar</c:calendar-description>
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

  it "reads calendar-description" do
    _(calendar_resource.calendar_description).must_equal 'Work calendar'
  end

  it "reads calendar-data" do
    _(event_resource.calendar_data).must_equal 'BEGIN:VCALENDAR'
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
