Shoes.setup do
  gem "twitter"
end

require "timeout"
require "twitter"

Shoes.app :title => "Twitter Shoes!", :width => 275, :height => 650, :resizable => false do
  
  ### SOME STUFF FOR LOCAL DEVELOPMENT!
  
  def testing_ui?
    # true
  end
  
  if testing_ui?
    def update_fixture_file(timeline)
      File.open(timeline_fixture_path, "w+") { |f| f.puts timeline.to_yaml }
    end
  
    def timeline_fixture_path
      File.join Dir.pwd, "timeline.yml"
    end
  end
  
  ## ERRRRRORRRRRR HANDLLLLLINNNGG!! (say in the voice of Jon Lovitz as The Thespian)
  
  def timeout(seconds = 1, &block)
    Timeout.timeout(seconds, &block)
  end
  
  def twitter_errors
    [Timeout::Error, ::Twitter::CantConnect]
  end
  
  def twitter_down!
    fail_whale
    maintenance_message
  end
  
  def fail_whale
    image "http://static.twitter.com/images/whale.png",
      :width => 275, :height => 200, :margin => 5
  end
  
  # Assuming that the maintenance page is up..
  def maintenance_message
    para *Hpricot(timeout { open("http://twitter.com") }).at("#content").
      to_s.scan(/>([^<]+)</).flatten. # XXX poor man's "get all descendant text nodes"
      reject { |x| x =~ /^\s*$/ }.    # except stuff that is just whitespace
      map { |x| x.squeeze(" ").strip }.join(" ")
  rescue Object => e
    para "Twitter is down down down. :("
    para e.message
  end
  
  ### NOW, ON VITH ZE SHOW!
  
  def twitter
    @twitter ||= begin
      timeout { Twitter::Base.new *File.readlines("cred").map(&:strip) }
    rescue *twitter_errors
    end
    twitter_down! unless @twitter
  end
  
  def update_status
    if testing_ui?
      status = Twitter::Status.new do |s|
        s.text = @status.text
        s.user = @timeline.first.user
        s.created_at = Time.new
        s.id = @timeline.first.id.to_i + 1
      end
      
      timeline = [status] + @timeline[0..-2]
      update_fixture_file timeline
    else
      status = begin
        timeout { twitter.update @status.text }
      rescue *twitter_errors
      end
    end
    
    reload_timeline
    reset_status
    
    raise "Timeline failed to update #{caller * "\n"}" unless status == @timeline.first
  end
  
  def load_timeline
    @timeline = if testing_ui?
      YAML.load_file(timeline_fixture_path)
    elsif twitter
      begin
        twitter.timeline
      rescue *twitter_errors
      end
    end || []
    @timeline = @timeline[0..9]
  end
  
  def reload_timeline
    load_timeline
    @timeline_stack.clear do
      if @timeline.any?
        @timeline.each do |s|
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
        twitter_down!
      end
    end
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
  
  def reset_status
    @status.text = ""
    @status.focus
  end
  
  ### LET ZE APP BEGIN!!
  
  update_fixture_file twitter.timeline if testing_ui? and not File.exist?(timeline_fixture_path)
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  @counter = strong ""
  
  ###
  
  @status = edit_line :width => -(40 + gutter), :margin_bottom => 3 do |s|
    @counter.text = (size = s.text.size).zero? ? "" : size
    @counter.style :stroke => (s.text.size > recommended_status_length ? red : black)
  end
  
  @submit = button "+" do
    update_status
  end
  
  para @counter, :size => 9, :margin => 0
  
  @timeline_stack = stack
  reload_timeline
  reset_status
  
  timer 60 do
    reload_timeline
  end
end
