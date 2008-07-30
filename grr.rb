module Grr
  def self.included(base)
    base.class_eval do
      if `which growlnotify` =~ /no growlnotify/i
        remove_method :growl
        info "growl not found on your system. app not extended with Grr."
      end
    end
  end
  
  def growl(status)
    `growlnotify -a Shoes.app -n "Aglet" -m "#{status.text}" #{status.user.screen_name}`
  end
end
