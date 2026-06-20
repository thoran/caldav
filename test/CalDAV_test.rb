# test/caldav_test.rb

require_relative './helper'

describe CalDAV do
  let(:base_uri){'https://caldav.example.com/'}
  let(:caldav){CalDAV.new(base_uri, username: 'user', password: 'pass')}

  let(:multistatus_response) do
    MockResponse.new(
      code: '207',
      message: 'Multi-Status',
      body: <<~XML,
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
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
        </d:multistatus>
      XML
    )
  end

  let(:created_response){MockResponse.new(code: '201', message: 'Created', body: '')}

  describe "#mkcalendar" do
    it "returns a Response" do
      caldav.stub(:request, created_response) do
        result = caldav.mkcalendar('/calendars/user/new/')
        _(result).must_be_kind_of WebDAV::Response
        _(result.code).must_equal 201
      end
    end
  end

  describe "#calendar_query" do
    it "returns a CalDAV::MultiStatus" do
      caldav.stub(:request, multistatus_response) do
        result = caldav.calendar_query('/calendars/user/work/', body: '<c:calendar-query/>')
        _(result).must_be_kind_of CalDAV::MultiStatus
        _(result.resources.first).must_be_kind_of CalDAV::Resource
      end
    end
  end

  describe "#calendar_multiget" do
    it "returns a CalDAV::MultiStatus" do
      caldav.stub(:request, multistatus_response) do
        result = caldav.calendar_multiget('/calendars/user/work/', body: '<c:calendar-multiget/>')
        _(result).must_be_kind_of CalDAV::MultiStatus
      end
    end
  end

  describe "#freebusy_query" do
    it "returns a raw Response carrying VFREEBUSY" do
      freebusy = MockResponse.new(code: '200', message: 'OK', body: 'BEGIN:VCALENDAR')
      caldav.stub(:request, freebusy) do
        result = caldav.freebusy_query('/calendars/user/work/', body: '<c:free-busy-query/>')
        _(result).must_be_kind_of WebDAV::Response
        _(result.body).must_equal 'BEGIN:VCALENDAR'
      end
    end
  end

  describe "#current_user_principal" do
    let(:response) do
      MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:">
          <d:response>
            <d:href>/</d:href>
            <d:propstat>
              <d:prop><d:current-user-principal><d:href>/dav/principals/user/abc/</d:href></d:current-user-principal></d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    it "returns the principal href as a bare URL string" do
      caldav.stub(:request, response) do
        _(caldav.current_user_principal).must_equal '/dav/principals/user/abc/'
      end
    end

    it "PROPFINDs the base URL's path by default, not '/'" do
      dav = CalDAV.new('https://caldav.example.com/dav/', username: 'u', password: 'p')
      captured = nil
      responder = ->(verb, path, **kw){captured = path; response}
      dav.stub(:request, responder) do
        dav.current_user_principal
      end
      _(captured).must_equal '/dav/'
    end

    it "extracts the principal from a pretty-printed (indented) response" do
      pretty = MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML)
        <?xml version="1.0" encoding="utf-8"?>
        <d:multistatus xmlns:d="DAV:">
          <d:response>
            <d:href>/dav/</d:href>
            <d:propstat>
              <d:prop>
                <d:current-user-principal>
                  <d:href>/dav/principals/user/abc/</d:href>
                </d:current-user-principal>
              </d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
      caldav.stub(:request, pretty) do
        _(caldav.current_user_principal).must_equal '/dav/principals/user/abc/'
      end
    end
  end

  describe "#calendar_home_set" do
    let(:response) do
      MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
          <d:response>
            <d:href>/dav/principals/user/abc/</d:href>
            <d:propstat>
              <d:prop><c:calendar-home-set><d:href>/dav/calendars/user/abc/</d:href></c:calendar-home-set></d:prop>
              <d:status>HTTP/1.1 200 OK</d:status>
            </d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    it "returns the home-set href as a bare URL string" do
      caldav.stub(:request, response) do
        _(caldav.calendar_home_set('/dav/principals/user/abc/')).must_equal '/dav/calendars/user/abc/'
      end
    end
  end

  describe "#calendars" do
    let(:response) do
      MockResponse.new(code: '207', message: 'Multi-Status', body: <<~XML)
        <?xml version="1.0" encoding="UTF-8"?>
        <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav" xmlns:cs="http://calendarserver.org/ns/">
          <d:response>
            <d:href>/dav/calendars/user/abc/</d:href>
            <d:propstat><d:prop><d:resourcetype><d:collection/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
          </d:response>
          <d:response>
            <d:href>/dav/calendars/user/abc/work/</d:href>
            <d:propstat><d:prop><d:resourcetype><d:collection/><c:calendar/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
          </d:response>
          <d:response>
            <d:href>/dav/calendars/user/abc/inbox/</d:href>
            <d:propstat><d:prop><d:resourcetype><d:collection/><c:schedule-inbox/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
          </d:response>
          <d:response>
            <d:href>/dav/calendars/user/abc/proxy/</d:href>
            <d:propstat><d:prop><d:resourcetype><d:collection/><cs:calendar-proxy-read/></d:resourcetype></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
          </d:response>
        </d:multistatus>
      XML
    end

    it "returns only the calendar collection hrefs as bare URL strings" do
      caldav.stub(:request, response) do
        _(caldav.calendars('/dav/calendars/user/abc/')).must_equal ['/dav/calendars/user/abc/work/']
      end
    end
  end
end
