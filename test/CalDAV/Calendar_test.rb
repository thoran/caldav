# test/CalDAV/Calendar_test.rb

require_relative '../helper'
require_relative '../../lib/CalDAV/Objects'

describe CalDAV::Calendar do
  let(:calendar) do
    CalDAV::Calendar.new(
      path: '/dav/calendars/user/test/work/',
      display_name: 'Work',
      ctag: 'abc123',
      color: '#FF0000',
      description: 'Work calendar',
      supported_components: 'VEVENT'
    )
  end

  describe "#path" do
    it "returns the path" do
      _(calendar.path).must_equal '/dav/calendars/user/test/work/'
    end
  end

  describe "#display_name" do
    it "returns the display name" do
      _(calendar.display_name).must_equal 'Work'
    end
  end

  describe "#ctag" do
    it "returns the ctag" do
      _(calendar.ctag).must_equal 'abc123'
    end
  end

  describe "#color" do
    it "returns the color" do
      _(calendar.color).must_equal '#FF0000'
    end
  end

  describe "#to_s" do
    it "returns the display name" do
      _(calendar.to_s).must_equal 'Work'
    end

    it "falls back to path when display_name is nil" do
      c = CalDAV::Calendar.new(path: '/dav/work/')
      _(c.to_s).must_equal '/dav/work/'
    end
  end

  describe ".from_resource" do
    let(:multistatus) do
      CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML))
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/" xmlns:ic="http://apple.com/ns/ical/">
          <d:response>
            <d:href>/calendars/user/work/</d:href>
            <d:propstat>
              <d:prop>
                <d:displayname>Work</d:displayname>
                <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
                <cs:getctag>abc123</cs:getctag>
                <ic:calendar-color>#FF0000</ic:calendar-color>
                <c:calendar-description>Work calendar</c:calendar-description>
                <c:calendar-timezone>BEGIN:VTIMEZONE</c:calendar-timezone>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end
    let(:built){CalDAV::Calendar.from_resource(multistatus.resources.first)}

    it "maps href to path" do
      _(built.path).must_equal '/calendars/user/work/'
    end

    it "maps displayname to display_name" do
      _(built.display_name).must_equal 'Work'
    end

    it "maps calendar-description to description" do
      _(built.description).must_equal 'Work calendar'
    end

    it "maps calendar-timezone to timezone" do
      _(built.timezone).must_equal 'BEGIN:VTIMEZONE'
    end

    it "maps getctag to ctag (extension, loaded by default)" do
      _(built.ctag).must_equal 'abc123'
    end

    it "maps calendar-color to color (extension, loaded by default)" do
      _(built.color).must_equal '#FF0000'
    end

    it "leaves ctag and color nil when those properties are absent" do
      body = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
          <d:response>
            <d:href>/calendars/user/plain/</d:href>
            <d:propstat>
              <d:prop><d:displayname>Plain</d:displayname></d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
      plain = CalDAV::Calendar.from_resource(CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: body)).resources.first)
      _(plain.ctag).must_be_nil
      _(plain.color).must_be_nil
    end
  end

  describe ".all" do
    let(:caldav){CalDAV.new('https://caldav.example.com/', username: 'u', password: 'p')}
    let(:home_response) do
      MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/" xmlns:ic="http://apple.com/ns/ical/">
          <d:response>
            <d:href>/dav/calendars/user/abc/</d:href>
            <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
          </d:response>
          <d:response>
            <d:href>/dav/calendars/user/abc/work/</d:href>
            <d:propstat>
              <d:prop>
                <d:displayname>Work</d:displayname>
                <d:resourcetype><d:collection/><c:calendar/></d:resourcetype>
                <cs:getctag>ctag-1</cs:getctag>
                <ic:calendar-color>#FF0000</ic:calendar-color>
                <c:calendar-description>Work calendar</c:calendar-description>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    it "returns Calendar objects for the calendar collections only" do
      caldav.stub(:request, home_response) do
        calendars = CalDAV::Calendar.all(client: caldav, home: '/dav/calendars/user/abc/')
        _(calendars.length).must_equal 1
        _(calendars.first).must_be_kind_of CalDAV::Calendar
        _(calendars.first.path).must_equal '/dav/calendars/user/abc/work/'
        _(calendars.first.display_name).must_equal 'Work'
      end
    end

    it "maps the extension properties when the extensions are loaded" do
      caldav.stub(:request, home_response) do
        work = CalDAV::Calendar.all(client: caldav, home: '/dav/calendars/user/abc/').first
        _(work.ctag).must_equal 'ctag-1'
        _(work.color).must_equal '#FF0000'
      end
    end

    it "requires a client" do
      _{CalDAV::Calendar.all(home: '/dav/calendars/user/abc/')}.must_raise ArgumentError
    end
  end
end
