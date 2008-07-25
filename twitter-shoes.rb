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

Shoes.app :title => "Twitter Shoes!", :width => 275, :height => 650, :resizable => false do
  extend TwitterShoes::Dev, TwitterShoes::Errors, TwitterShoes::Helpers
  
  ###
  
  def twitter_cred_path
    File.expand_path "~/.twittershoes_cred"
  end
  
  def twitter
    @twitter ||= ::Twitter::Base.new *File.readlines(twitter_cred_path).map(&:strip)
  end
  
  ###
  
  def load_timeline
    @timeline = if testing_ui?
      YAML.load_file(timeline_fixture_path)
    else
      begin
        twitter.timeline
      rescue *twitter_errors
      end
    end || []
    
    @timeline = @timeline[0..9]
  end
  
  def reload_timeline
    info "reloading timeline"
    load_timeline
    @timeline_stack.clear do
      if @timeline.any?
        
        @timeline.each do |status|
          flow :margin => 0 do
            zebra_stripe gray(0.9)
            
            stack :width => -(45 + gutter) do
              with_options :margin => 5 do |s|
                s.para(*(autolink(status.text) + [:size => 9]))
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
      
      else
        twitter_down!
      end
    end
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
      status = begin
        timeout { twitter.update @status.text }
      rescue *twitter_errors
      end
    end
    
    reload_timeline
    reset_status
  end
  
  ###
  
  def reset_status
    @status.text = ""
    @counter.text = ""
    @status.focus
  end
  
  ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ### ###
  
  # if not File.exist?(twitter_cred_path)
  #   name = ask "user name?"
  #   pass = ask "password?"
  #   alert "Thank you, this info is now stored at #{twitter_cred_path}"
  #   File.open(twitter_cred_path, "w+") { |f| f.puts name, pass }
  # end
  
  # TODO refactor out a fetch_timeline method or some such that uses 
  # error handling for previous twitter.timeline calls
  if testing_ui? and not File.exist?(timeline_fixture_path)
    update_fixture_file twitter.timeline
  end
  
  ###
  
  background white
  
  # Longer entries will be published in full but truncated for mobile devices.
  recommended_status_length = 140
  
  flow do
    background black
    
    @status = edit_line :width => -(55 + gutter), :margin_bottom => 3, :margin_right => 5 do |s|
      @counter.text = (size = s.text.size).zero? ? "" : size
      @counter.style :stroke => (s.text.size > recommended_status_length ? red : @counter_default_stroke)
    end
    
    @submit = button "+", :margin_right => 0 do
      update_status
    end

    @counter_default_stroke = white
    @counter = strong ""
    para @counter, :size => 9, :margin => 0, :margin_top => 8, :stroke => @counter_default_stroke
  end
  
  @timeline_stack = stack
  
  stack :margin_top => 10 do
    background black
    para "©2008 ", link("GREATsethPECTATIONS", :click => "http://greatseth.com"), :stroke => white
  end
  
  reload_timeline
  reset_status
  
  every 60 do
    reload_timeline
  end
end
