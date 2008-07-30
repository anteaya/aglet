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
      @latest_growl ? (s.id > @latest_growl) : true
    end
    
    too_many = statuses.size > GROWL_LIMIT
    
    statuses = statuses[0..(GROWL_LIMIT - 1)] if too_many
    
    statuses.each { |s| growl s.user.screen_name, s.text }
    
    growl "You have #{statuses.size - GROWL_LIMIT} more new updates!" if too_many
    
    @latest_growl = statuses.last
  end
  
  def growl(message, heading = "Aglet")
    `growlnotify -a Shoes.app -n "Aglet" -m "#{message}" #{heading}`
  end
end
