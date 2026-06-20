# CalDAV/MultiStatus.rb
# CalDAV::MultiStatus

require 'webdav'

require_relative './Resource'

class CalDAV < WebDAV
  class MultiStatus < WebDAV::MultiStatus

    private

    def parse_response(response_element)
      CalDAV::Resource.new(super)
    end

    # Interim: webdav 0.2.0's parse_properties does `text || to_s`, so a nested
    # property (resourcetype, current-user-principal, calendar-home-set) whose
    # server pretty-prints the XML yields the inter-tag whitespace instead of the
    # markup, dropping the nested elements. Treat blank text as absent so such
    # properties fall through to their serialised form, as they do for compact
    # servers. Dissolves when webdav is reworked.
    def parse_properties(prop_element)
      return {} unless prop_element
      prop_element.elements.to_a.each_with_object({}) do |property_element, result|
        result[property_element.namespace] ||= {}
        text = property_element.text
        value = text && !text.strip.empty? ? text : property_element.to_s
        result[property_element.namespace][property_element.name] = value
      end
    end
  end
end
