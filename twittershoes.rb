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
    # twitter.timeline[0..9]
    
    create_timeline_fixture! unless File.exist? timeline_fixture_path
    YAML.load_file(timeline_fixture_path)[0..9]
  end
  
  def reload_timeline
    @timeline = load_timeline
  end
  
  ###
  
  def create_timeline_fixture!
    File.open timeline_fixture_path, "w+" do |f|
      f.puts twitter.timeline.to_yaml
    end
  end
  
  def timeline_fixture_path
    File.join Dir.pwd, "timeline"
  end
  
  ###
  
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
  
  def set_background(user)
    # url = begin
    #   Timeout.timeout 1 do
    #     open("http://twitter.com/#{user.screen_name}").
    #       read[/url\((http:\/\/.+profile_background_images.+?)\)/, 1]
    #   end
    # rescue Object => e
    #   rgb rand(255), rand(255), rand(255)
    # end
    # 
    # background url if url
    
    @on = @on ? (background(gray(0.9)); nil) : true
    # background user.profile_image_url
  end
  
  ###
  
  populate_timeline = proc do
    timeline.each do |s|
      flow do
        set_background s.user
        caption(*(autolink(s.text) + [:size => 9, :margin_left => 45, :margin_bottom => 5])) 
        # image s.user.profile_image_url, :width => 45, :height => 45, :radius => 5, :margin => 5 rescue nil
      end
    end
  end
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  @counter = strong ""
  
  @timeline_stack = stack({ :margin => 5, :margin_right => 7 }, &populate_timeline)
  
  stack do
    flow do
      @status = edit_line :width => "95%", :margin_bottom => 3 do |s|
        @counter.text = (size = s.text.size).zero? ? "" : size
        @counter.style :stroke => (s.text.size > recommended_status_length ? red : black)
      end
      
      def @status.reset
        self.text = ""
        focus
      end
      
      para @counter, :size => 9, :margin_left => 5
    end
    
    button "tweet" do
      twitter.update @status.text
      reload_timeline
      @timeline_stack.clear &populate_timeline
      @status.reset
    end
  end
  
  @status.reset
  # timer(60) { reload_timeline }
end
