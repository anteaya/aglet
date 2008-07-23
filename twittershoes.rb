Shoes.setup do
  gem "twitter"
end

require "timeout"
require "twitter"

Shoes.app :title => "Twitter Shoes!", :width => 275, :height => 650, :resizable => false do
  def twitter
    @twitter ||= Twitter::Base.new "greatseth", "skippy"
  end
  
  def timeline
    @timeline ||= load_timeline
  end
  
  def load_timeline
    twitter.timeline[0..9]
    
    # create_timeline_fixture! unless File.exist? timeline_fixture_path
    # YAML.load_file(timeline_fixture_path)[0..9]
  end
  
  def reload_timeline
    alert "reloading timeline!"
    @timeline = nil
    @timeline_stack.clear do
      if timeline.any?
        timeline.each do |s|
          flow do
            set_background s.user
            flow :width => -(45 + gutter) do
              para(*(autolink(s.text) + [:size => 9, :margin => 5, :margin_bottom => 0]))
            end
            flow :width => 45 do
              image s.user.profile_image_url, :width => 45, :height => 45, :radius => 5, :margin => 5
            end
          end
        end
      else
        # Twitter is down
        fail_whale
        maintenance_message
      end
    end
  end
  
  def fail_whale
    image "http://static.twitter.com/images/whale.png",
      :width => 275, :height => 200, :margin => 5
  end
  
  # Assuming that the maintenance page is up..
  def maintenance_message
    para *Hpricot(open("http://twitter.com")).at("#content").
      to_s.scan(/>([^<]+)</).flatten. # XXX poor man's "get all descendant text nodes"
      reject { |x| x =~ /^\s*$/ }.    # except stuff that is just whitespace
      map { |x| x.squeeze(" ").strip }.join(" ")
  end
  
  ###
  
  def set_background(user)
    # begin
    #   url = Timeout.timeout 1 do
    #     open("http://twitter.com/#{user.screen_name}").
    #       read[/url\((http:\/\/.+profile_background_images.+?)\)/, 1]
    #   end
    #   background url if url
    # rescue Object
    # end
    
    # background user.profile_image_url
    
    zebra_stripe gray(0.9)
  end
  
  def zebra_stripe(color)
    @zebra_stripe = if @zebra_stripe
      background color
      false
    else
      true
    end
  end
  
  def autolink(status)
    status.strip.scan(/(\S+)(\s+)?/).flatten.map do |token|
      case token
      when /@\S+/
        link token, :click => "http://twitter.com/#{token[1..-1]}"
      when /http:\/\/\S+/
        link token, :click => token
      else token
      end
    end
  end
  
  ### LET THE APP BEGIN!!
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  @counter = strong ""
  
  ###
  
  @status = edit_line :width => -(40 + gutter), :margin_bottom => 3 do |s|
    @counter.text = (size = s.text.size).zero? ? "" : size
    @counter.style :stroke => (s.text.size > recommended_status_length ? red : black)
  end
  
  def @status.reset
    self.text = ""
    focus
  end
  
  @submit = button "+" do
    twitter.update @status.text
    reload_timeline
    @status.reset
  end
  
  para @counter, :size => 9, :margin => 0
  
  @timeline_stack = stack
  reload_timeline
  
  ### BEGIN THE INIT CODE!!
  
  @status.reset
  timer 60 do
    reload_timeline
  end
  
  ### AND NOW SOME STUFF FOR LOCAL DEVELOPMENT!
  
  def create_timeline_fixture!
    File.open timeline_fixture_path, "w+" do |f|
      f.puts twitter.timeline.to_yaml
    end
  end
  
  def timeline_fixture_path
    File.join Dir.pwd, "timeline"
  end
end
