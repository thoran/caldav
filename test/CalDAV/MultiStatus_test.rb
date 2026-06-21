# test/CalDAV/MultiStatus_test.rb

require_relative '../helper'

describe CalDAV::MultiStatus do
  let(:body) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <d:multistatus xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:response>
          <d:href>/calendars/user/work/</d:href>
          <d:propstat>
            <d:prop>
              <d:resourcetype>
                <d:collection/>
                <c:calendar/>
              </d:resourcetype>
              <c:calendar-description>Work calendar</c:calendar-description>
            </d:prop>
            <d:status>HTTP/1.1 200 OK</d:status>
          </d:propstat>
        </d:response>
        <d:response>
          <d:href>/calendars/user/home/</d:href>
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
  end
  let(:multistatus){CalDAV::MultiStatus.new(MockResponse.new(code: '207', message: 'Multi-Status', body: body))}
  let(:work){multistatus.resources[0]}
  let(:work_properties){work.propstats.first[:properties]}

  it "parses one resource per response element" do
    _(multistatus.resources.size).must_equal 2
  end

  it "wraps every response as a CalDAV::Resource" do
    _(multistatus.resources.map(&:class).uniq).must_equal [CalDAV::Resource]
  end

  it "preserves response order" do
    _(multistatus.resources.collect(&:href)).must_equal ['/calendars/user/work/', '/calendars/user/home/']
  end

  it "keeps a pretty-printed nested property as serialised markup, not whitespace" do
    _(work_properties[CalDAV::DAV_NAMESPACE]['resourcetype']).must_match(%r{<(?:\w+:)?calendar})
  end

  it "keeps a flat property's text" do
    _(work_properties[CalDAV::NAMESPACE]['calendar-description']).must_equal 'Work calendar'
  end
end
