# test/vcr_helper_test.rb

require_relative './helper'
require_relative './vcr_helper'

describe 'anonymise_account_path' do
  it "replaces the id under a principals collection" do
    _(anonymise_account_path('/dav/principals/user/john@example.net/')).must_equal '/dav/principals/user/anon/'
  end

  it "replaces the id under a calendars collection, keeping the calendar name" do
    _(anonymise_account_path('/dav/calendars/user/abc123/work/')).must_equal '/dav/calendars/user/anon/work/'
  end

  it "replaces an opaque (non-email) id" do
    _(anonymise_account_path('/dav/principals/user/u9f8e7d6/')).must_equal '/dav/principals/user/anon/'
  end

  it "anonymises ids inside a serialised response body" do
    body = '<d:href>/dav/calendars/user/abc123/</d:href>'
    _(anonymise_account_path(body)).must_equal '<d:href>/dav/calendars/user/anon/</d:href>'
  end

  it "leaves unrelated paths untouched" do
    _(anonymise_account_path('/dav/')).must_equal '/dav/'
  end

  it "handles nil" do
    _(anonymise_account_path(nil)).must_be_nil
  end
end
