# test/CalDAV/Objects/Core_test.rb

require_relative '../../helper'
require 'CalDAV/Objects/Core'

# The core path loads the object layer without the extension accessors. Their
# absence can't be asserted in-process — requires are global, and another test
# loads the full 'CalDAV/Objects' — so this covers only that the path itself
# resolves and yields the objects; the opt-out is a structural property of
# Core.rb not requiring Resource/Extensions.
describe "CalDAV/Objects/Core" do
  it "loads the object layer through the core require path" do
    _(defined?(CalDAV::Calendar)).must_equal 'constant'
  end
end
