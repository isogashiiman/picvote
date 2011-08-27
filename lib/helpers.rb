require 'cgi'

class String
  def decode
    CGI.unescape self
  end
end

class DateTime
  def same_day_as(other)
    day == other.day and month = other.month and year = other.year
  end
end
