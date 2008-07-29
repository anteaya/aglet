module Aglet
module Grr
  def self.extended(base)
    base.instance_eval do
      if `which growlnotify` =~ / no /
        undef :growl
        info "growl not found on your system. app not extended with Grr."
      end
    end
  end
  
  def growl(status)
    `growlnotify -m #{status.text}`
  end
end
end
