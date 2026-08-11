# test/CalDAV/Objects_test.rb

require_relative '../helper'

# Exercise the Layer 2 entry point through its real public require path, so this
# guards the path itself (the CalDAV-cased, portable form) — not just the file's
# contents. lib is on the load path under rake's TestTask, as it is for a
# consumer of the installed gem.
require 'CalDAV/Objects'

describe "CalDAV/Objects" do
  it "loads the object layer through the require path" do
    _(defined?(CalDAV::Calendar)).must_equal 'constant'
  end

  it "pulls in the Layer 1 base it builds on" do
    _(CalDAV.ancestors).must_include(WebDAV)
    _(defined?(CalDAV::Resource)).must_equal 'constant'
  end

  it "loads the extension accessors by default" do
    _(CalDAV::Resource.method_defined?(:getctag)).must_equal true
    _(CalDAV::Resource.method_defined?(:calendar_color)).must_equal true
  end

  it "composes every loaded extension into the calendars request" do
    caldav = CalDAV.new('https://caldav.example.com/', username: 'u', password: 'p')
    body = caldav.send(:calendars_body)
    _(body).must_include 'xmlns:cs="http://calendarserver.org/ns/"'
    _(body).must_include '<cs:getctag/>'
    _(body).must_include 'xmlns:ic="http://apple.com/ns/ical/"'
    _(body).must_include '<ic:calendar-color/>'
  end
end
