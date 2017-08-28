class String
  class << self
    # Try to convert the specified text from UTF-8 to SJIS
    def safe_iconv(str_utf8)
      begin
        Iconv.iconv('SHIFT_JIS//IGNORE//TRANSLIT','UTF-8',str_utf8)[0]
      rescue Exception => e
        Rails.logger.error("invalide character sequence {#{e.message}}")
        Kconv::tosjis(str_utf8)
      end
    end
  end

  def to_html
    html_value = ERB::Util.html_escape(self).gsub(/\n/,'<br>')
    html_value.strip.empty? ? '&nbsp;' : html_value
  end

  #   String.to_date -> date
  # Parse the date formatted string to a date value. 
  # For invalid date formats, or nil, a Date#null_date will be returned
  #   '2000/01/01'.to_date  #=> Sat, 01 Jan 2000
  #   '12/31/2000'.to_date  #=> Sun, 31 Dec 2000
  #   '31/12/2000'.to_date  #=> Thu, 01 Mar 2000
  #   '2001/02/29'.to_date  #=> Thu, 01 Mar 2000
  #   '0000/00/00'.to_date  #=> Thu, 01 Mar 2000
  #   '9999/99/99'.to_date  #=> Thu, 01 Mar 2000
  #   'Not a Date'.to_date  #=> Thu, 01 Mar 2000
  #   ''.to_date            #=> Thu, 01 Mar 2000
  def to_date
    begin
      super
    rescue
      Date.null_date
    end
  end
end

# This below fixes a bad memory leak in ruby 1.8.6
# http://blog.edhickey.com/2008/12/03/memory-leak-in-ruby-186-string-class/
class String  
#  alias :non_garbage_split :split
#  alias :non_garbage_gsub :gsub
#  alias :non_garbage_gsub! :gsub!

#  def split(char, limit = 0)
#    holder = char
#    non_garbage_split(holder, limit)
#  end
  
#  def gsub(*args, &block)
#    if args.size == 1
#      non_garbage_gsub(args[0], &block)
#    else
#      non_garbage_gsub(args[0], args[1], &block)
#    end
#  end
#
#  def gsub!(*args, &block)
#    holder = args[0]
#    args[0] = holder
#    non_garbage_gsub!(*args, &block)
#  end
end

#end memory leak fixes