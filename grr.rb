module Grr
  def self.included(base)
    base.class_eval do
      if `which growlnotify` =~ /no growlnotify/i
        public_instance_methods.each { |m| remove_method m }
        info "growl not found on your system. app not extended with Grr."
      end
    end
  end
  
  GROWL_LIMIT = 4
  
  def growl_latest
    statuses = @timeline.select do |s|
      # XXX Apparently not always an ID? wtf?
      @latest_growl ? (s.id && s.id > @latest_growl.id) : true
    end
    
    too_many = statuses.size > GROWL_LIMIT
    
    statuses = statuses[0..(GROWL_LIMIT - 1)] if too_many
    
    statuses.each { |s| growl s.text, s.user.screen_name }
    
    growl "You have #{statuses.size - GROWL_LIMIT} more new updates!" if too_many
    
    @latest_growl = statuses.last
  end
  
  def growl(message, heading = "Aglet")
    `growlnotify -a Shoes.app -n "Aglet" -m "#{message}" #{heading}`
  end
end
