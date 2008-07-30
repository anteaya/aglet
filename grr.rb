module Grr
  def self.included(base)
    base.class_eval do
      if `which growlnotify` =~ / no /
        remove_method :growl
        info "growl not found on your system. app not extended with Grr."
      end
    end
  end
  
  def growl(status)
    `growlnotify -m #{status.text}`
  end
end
