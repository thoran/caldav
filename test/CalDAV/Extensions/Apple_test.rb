# test/CalDAV/Extensions/Apple_test.rb

require_relative '../../helper'
require 'CalDAV/Objects' # loads the vendor extensions

describe "CalDAV::Extensions::Apple" do
  let(:resource) do
    body = <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:ic="http://apple.com/ns/ical/">
        <d:response>
          <d:href>/calendars/user/work/</d:href>
          <d:propstat><d:prop><ic:calendar-color>#FF0000</ic:calendar-color></d:prop><d:status>HTTP/1.1 200 OK</d:status></d:propstat>
        </d:response>
      </d:multistatus>
    XML
    CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: body)).resources.first
  end

  it "reads calendar-color from the apple namespace" do
    _(resource.calendar_color).must_equal '#FF0000'
  end

  it "contributes its namespace and property to the calendars request" do
    caldav = CalDAV.new('https://caldav.example.com/', username: 'u', password: 'p')
    body = caldav.send(:calendars_body)
    _(body).must_include 'xmlns:ic="http://apple.com/ns/ical/"'
    _(body).must_include '<ic:calendar-color/>'
  end
end
