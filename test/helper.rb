# test/helper.rb

require 'minitest/autorun'
require 'minitest/mock'
require 'minitest/spec'

require_relative '../lib/caldav'

MockResponse = Struct.new(:code, :message, :body, :headers_hash, keyword_init: true) do
  def [](key)
    headers_hash&.dig(key)
  end
end
