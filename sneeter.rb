Shoes.setup do
  gem "twitter"
end

%w(
timeout
twitter

dev
errors
helpers
).each { |x| require x }

Shoes.app :title => "Twitter Shoes!", :width => 275, :height => 585, :resizable => false do
  extend TwitterShoes::Dev, TwitterShoes::Errors, TwitterShoes::Helpers
  
  cred_path = File.expand_path "~/.twittershoes_cred"
  
  @twitter = ::Twitter::Base.new *File.readlines(cred_path).map(&:strip)
  
  @friends = twitter_api { @twitter.friends.map(&:name) }
  
  ###
  
  def load_timeline
    @timeline = (
      if testing_ui?
        YAML.load_file(timeline_fixture_path)
      else
        load_timeline_from_api
      end || []
    ).first(10)
  end
  
  def load_timeline_from_api
    twitter_api { @twitter.timeline }
  end
  
  def reload_timeline
    info "reloading timeline"
    load_timeline
    @timeline_stack.clear { @timeline.any? ? populate_timeline : twitter_down! }
  end
  
  def update_status
    if testing_ui?
      status = ::Twitter::Status.new do |s|
        s.text = @status.text
        s.user = @timeline.first.user
        s.created_at = Time.new
        s.id = @timeline.first.id.to_i + 1
      end
      
      timeline = [status] + @timeline[0..-2]
      update_fixture_file timeline
    else
      twitter_api { @twitter.update @status.text }
    end
    
    reload_timeline
    reset_status
  end
  
  # Layout for timeline
  def populate_timeline
    @timeline.each do |status|
      flow :margin => 0 do
        zebra_stripe gray(0.9)
        
        stack :width => -(45 + gutter) do
          with_options :margin => 5 do |s|
            s.para autolink(status.text), :size => 9
            s.para "#{time_ago status.created_at} ago",
              :size => 8, :margin_top => 0, :stroke => gray
          end
        end
        
        stack :width => 45 do
          image status.user.profile_image_url,
            :width => 45, :height => 45, :radius => 5, :margin => 5
        end
      end
    end
  end
  
  def reset_status
    @status.text = ""
    @counter.text = ""
    @status.focus
  end
  
  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
  
  # if not File.exist?(cred_path)
  #   name = ask "user name?"
  #   pass = ask "password?"
  #   alert "Thank you, this info is now stored at #{cred_path}"
  #   File.open(cred_path, "w+") { |f| f.puts name, pass }
  # end
  
  if testing_ui? and not File.exist?(timeline_fixture_path)
    update_fixture_file load_timeline_from_api
  end
  
  ###
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  status_offset = -30
  flow :margin => [0,0,0,5]do # :top => status_offset do
    background black
    
    # hover do
    #   style :top => 0
    # end
    # 
    # leave do
    #   style :top => status_offset
    # end
    
    ###
    
    @status = edit_line :width => -(55 + gutter), :margin => [0,0,5,0] do |s|
      @counter.text = (size = s.text.size).zero? ? "" : size
      @counter.style :stroke => (s.text.size > recommended_status_length ? red : @counter_default_stroke)
    end
    
    @submit = button "»", :margin => 0 do
      update_status
    end
    
    @counter_default_stroke = white
    @counter = strong ""
    para @counter, :size => 9, :margin => [0,8,0,0], :stroke => @counter_default_stroke
  end
  
  @timeline_stack = stack :height => 500, :scroll => true
  
  stack :height => 43 do
    background black
    # para "©2008 ", link("GREATsethPECTATIONS", :click => "http://greatseth.com", :hover => false),
    #       :stroke => white, :margin => [0,5,0,0], :align => "center"
  end
  
  ###
  
  reload_timeline
  reset_status
  
  every 60 do
    reload_timeline
  end
end
