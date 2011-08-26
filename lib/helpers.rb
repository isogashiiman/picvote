require 'cgi'

class String
  def decode
    CGI.unescape self
  end
end
