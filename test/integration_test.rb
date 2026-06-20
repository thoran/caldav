# test/integration_test.rb

require_relative './helper'
require_relative './vcr_helper'

describe 'CalDAV integration' do
  let(:caldav){caldav_client}

  let(:events_query_body) do
    <<~XML
      <?xml version="1.0" encoding="UTF-8"?>
      <c:calendar-query xmlns:d="DAV:" xmlns:c="urn:ietf:params:xml:ns:caldav">
        <d:prop>
          <d:getetag/>
          <c:calendar-data/>
        </d:prop>
        <c:filter>
          <c:comp-filter name="VCALENDAR">
            <c:comp-filter name="VEVENT"/>
          </c:comp-filter>
        </c:filter>
      </c:calendar-query>
    XML
  end

  it "discovers principal, home-set and calendars as bare URL strings" do
    with_caldav_cassette('discovery') do
      principal = caldav.current_user_principal
      _(principal).must_be_kind_of String
      _(principal).wont_include '<'
      home = caldav.calendar_home_set(principal)
      _(home).must_be_kind_of String
      _(home).wont_include '<'
      calendars = caldav.calendars(home)
      _(calendars).must_be_kind_of Array
      calendars.each do |href|
        _(href).must_be_kind_of String
        _(href).wont_include '<'
      end
    end
  end

  it "queries the first calendar and returns CalDAV resources" do
    with_caldav_cassette('calendar_query') do
      calendar = caldav.calendars.first
      skip 'no calendars on this account' unless calendar
      result = caldav.calendar_query(calendar, body: events_query_body)
      _(result).must_be_kind_of CalDAV::MultiStatus
      result.resources.each{|resource| _(resource).must_be_kind_of CalDAV::Resource}
    end
  end
end
