module Helpers
  def link_to_status(status)
    link time_ago(status.created_at),
      :click => "http://twitter.com/#{status.user.screen_name}/statuses/#{status.id}"
  end
  
  def link_to_reply(user)
    link "reply" do
      @status.text += "@#{user.screen_name} "
      @status.focus
    end
  end
  
  def link_to_direct(user)
    link "direct" do
      @status.text += "d #{user.screen_name} "
      @status.focus
    end
  end
  
  def link_to_profile(user)
    link user.screen_name, :click => "http://twitter.com/#{user.screen_name}"
  end
  
  ###
  
  def menu_for(status)
    flow :margin => [5,0,0,0] do
      with_options :size => 7, :margin => [0,0,5,5] do |m|
        m.para link_to_status(status)
        if not you?(status.user)
          @menus[status.id] = m.para(
            link_to_reply(status.user), " ",
            link_to_direct(status.user)
          )
        end
      end
      # menu_toggle(status).call
    end
  end
  
  def you?(user)
    @cred[0] == user.screen_name
  end
  
  def avatar_for(user)
    image user.profile_image_url,
      :width => 45, :height => 45, :radius => 5, :margin => [5,5,5,3]
  end
  
  ###
  
  def zebra_stripe(color)
    @zebra_stripe = if @zebra_stripe
      background color
      false
    else
      true
    end
  end
  
  ###
  
  def at_pattern
    "[^\s!?.]+"
  end
  
  def autolink(status)
    # XXX temp hack for bug about too much escaping :\
    status = CGI.unescapeHTML(CGI.unescapeHTML(status))
    
    status.strip.scan(/(\S+)(\s+)?/).flatten.map do |token|
      case token
      when /^@#{at_pattern}$/
        link token, :click => "http://twitter.com/#{username_from token}"
      when /^(http:\/\/|www\.)\S+$/
        link token, :click => "#{"http://" if $1 =~ /www/}#{token}"
      else token
      end
    end
  end
  
  # A @username token might be grabbed with an attached piece of punctuation or similar
  # when parsing the status text for linkable tokens.
  def username_from(at_token)
    at_token[1..-1][Regexp.new(at_pattern)]
  end
  
  ###
  
  # Based on distance_of_time_in_words from Rails' ActionView.
  def time_ago(from, to = Time.new, include_seconds = false)
    from = Time.parse from
    
    distance = (to - from).abs
    minutes  = (distance / 60).round
    seconds  = distance.round
    
    case minutes
      when 0..1
        return (minutes == 0) ? "< 1 min" : "1 min" unless include_seconds
        case seconds
          when 0..4   then '< 5s'
          when 5..9   then '< 10s'
          when 10..19 then '< 20s'
          when 20..39 then '30s'
          when 40..59 then '< 1 min'
          else             '1 min'
        end

      when 2..44           then "#{minutes} min"
      when 45..89          then '1 hr'
      when 90..1439        then "#{(minutes.to_f / 60.0).round} hrs"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(minutes / 1440).round} days"
      when 43200..86399    then '1 month'
      when 86400..525599   then "#{(minutes / 43200).round} months"
      when 525600..1051199 then '1 yr'
      else                      "over #{(minutes / 525600).round} yrs"
    end
  end
  
  # def time_ago_bg(from, to = Time.new, include_seconds = false)
  #   from = Time.parse from
  #   
  #   distance = (to - from).abs
  #   minutes  = (distance / 60).round
  #   seconds  = distance.round
  #   
  #   sec = [0.99, 0.95, 0.9, 0.85].map { |x| gray x }
  #   min = gray(0.7)
  #   hrs = gray(0.5)
  #   day = gray(0.3)
  #   yrs = gray(0.1)
  #   
  #   bg = case minutes
  #     when 0..1
  #       return background(min) unless include_seconds
  #       case seconds
  #         when 0..4   then sec[0]
  #         when 5..9   then sec[1]
  #         when 10..19 then sec[2]
  #         when 20..39 then sec[3]
  #         when 40..59 then min
  #         else             min
  #       end
  #     
  #     when 2..44           then min
  #     when 45..89          then hrs
  #     when 90..1439        then hrs
  #     when 1440..2879      then day
  #     when 2880..43199     then day
  #     when 43200..86399    then yrs # months
  #     when 86400..525599   then yrs # months
  #     when 525600..1051199 then yrs
  #     else                      yrs
  #   end
  #   
  #   background bg
  # end
end
