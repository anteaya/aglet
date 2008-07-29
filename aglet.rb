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

Shoes.app :title => "aglet", :width => 275, :height => 565, :resizable => false do
  @top = self
  
  extend Aglet::Dev, Aglet::Errors, Aglet::Helpers
  
  ###
  
  @cred_path = File.expand_path("~/.aglet_cred")
  
  if not File.exist?(@cred_path)
    # name = ask "user name?"
    # pass = ask "password?"
    # File.open(@cred_path, "w+") { |f| f.puts name, pass }
    # alert "Thank you, this info is now stored at #{@cred_path}"
    
    alert "Sorry, but you must create a file at #{@cred_path} with two lines:\n\nUSERNAME\nPASSWORD\n\nThis app is young. We will fix that some day!"
    exit!
  end
  
  @cred = File.readlines(@cred_path).map(&:strip)
  
  ###
  
  @twitter = Twitter::Base.new *@cred
  
  # @friends = twitter_api { @twitter.friends.map(&:name) }
  
  ###
  
  def load_timeline
    @timeline = (
      if testing_ui?
        update_fixture_file load_timeline_from_api if not File.exist?(timeline_fixture_path)
        load_timeline_from_cache
      else
        load_timeline_from_api
      end || []
    ).first(10)
    
    update_fixture_file @timeline
  end
  
  def load_timeline_from_api
    twitter_api { @twitter.timeline }
  end
  
  def load_timeline_from_cache
    YAML.load_file timeline_fixture_path
  end
  
  @first_load = true
  
  def reload_timeline
    info "reloading timeline"
    load_timeline
    
    if @timeline.any?
      @timeline_stack.clear { populate_timeline }
    
    elsif not @first_load
      warn "timeline reloaded empty, Twitter is probably over capacity"
    
    else
      msg = "Twitter is over capacity at the moment, " <<
        "but the timeline will continue to attempt to reload in the background."
      info  msg
      alert msg
      
      @timeline = [fail_status] + load_timeline_from_cache
      @timeline_stack.clear { populate_timeline }
    
    end
    
    @first_load = false
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
  
  def menu_toggle(status)
    proc { @menus[status.id].toggle }
  end
  
  # Layout for timeline
  def populate_timeline
    @menus = {}
    @timeline.each do |status|
      flow :margin => 0 do
        zebra_stripe gray(0.9)
        
        stack :width => -(45 + gutter) do
          para autolink(status.text), :size => 9, :margin => 5
          menu_for status
        end
        
        # hover &menu_toggle(status)
        # leave &menu_toggle(status)
        
        stack :width => 45 do
          avatar_for status.user
          para link_to_profile(status.user), :size => 7, :align => "right",
            :margin => [0,0,5,5]
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
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  @form = flow :margin => [0,0,0,5] do
    background fail_whale_blue
    
    @status = edit_box :width => -(55 + gutter), :height => 35, :margin => [5,5,5,0] do |s|
      if s.text.chomp!
        update_status
      else
        @counter.text = (size = s.text.size).zero? ? "" : size
        @counter.style :stroke => (s.text.size > recommended_status_length ? red : @counter_default_stroke)
      end
    end
    
    @submit = button "»", :margin => 0 do
      update_status
    end
    
    @counter_default_stroke = white
    @counter = strong ""
    para @counter, :size => 8, :margin => [0,8,0,0], :stroke => @counter_default_stroke
  end
  
  @timeline_stack = stack :height => 500, :scroll => true
  
  stack :height => 28 do
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
