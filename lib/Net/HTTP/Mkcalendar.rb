# Net/HTTP/Mkcalendar.rb
# Net::HTTP::Mkcalendar

require 'net/http'

module Net
  class HTTP
    class Mkcalendar < Net::HTTPRequest

      METHOD = 'MKCALENDAR'
      REQUEST_HAS_BODY = true
      RESPONSE_HAS_BODY = true

    end
  end
end
