# test/Net/HTTP/Mkcalendar_test.rb

require_relative '../../helper'

describe Net::HTTP::Mkcalendar do
  it "is a subclass of Net::HTTPRequest" do
    _(Net::HTTP::Mkcalendar < Net::HTTPRequest).must_equal(true)
  end

  it "has the correct METHOD" do
    _(Net::HTTP::Mkcalendar::METHOD).must_equal('MKCALENDAR')
  end

  it "accepts a body" do
    _(Net::HTTP::Mkcalendar::REQUEST_HAS_BODY).must_equal(true)
  end

  it "expects a response body" do
    _(Net::HTTP::Mkcalendar::RESPONSE_HAS_BODY).must_equal(true)
  end
end
