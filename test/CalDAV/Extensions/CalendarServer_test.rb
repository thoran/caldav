# test/CalDAV/Extensions/CalendarServer_test.rb

require_relative '../../helper'
require 'CalDAV/Objects' # loads the vendor extensions

describe "CalDAV::Extensions::CalendarServer" do
  let(:resource) do
    body = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:cs="http://calendarserver.org/ns/">
        <d:response>
          <d:href>/calendars/user/work/</d:href>
          <d:propstat><d:prop><cs:getctag>abc123</cs:getctag></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
        </d:response>
      </d:multistatus>
    XML
    CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: body)).resources.first
  end

  it "reads getctag from the calendarserver namespace" do
    _(resource.getctag).must_equal 'abc123'
  end

  it "contributes its namespace and property to the calendars request" do
    caldav = CalDAV.new('https://caldav.example.com/', username: 'u', password: 'p')
    body = caldav.send(:calendars_body)
    _(body).must_include 'xmlns:cs="http://calendarserver.org/ns/"'
    _(body).must_include '<cs:getctag/>'
  end
end
