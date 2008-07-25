module TwitterShoes
module Helpers
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
      when /(http:\/\/|www\.)\S+/
        link token, :click => "#{"http://" if $1 =~ /www/}#{token}"
      else token
      end
    end
  end
  
  # Based on distance_of_time_in_words from Rails' ActionView.
  def time_ago(from, to = Time.new, include_seconds = false)
    from = Time.parse from
    
    distance = (to - from).abs
    minutes  = (distance / 60).round
    seconds  = distance.round
    
    case minutes
      when 0..1
        return (minutes == 0) ? 'less than a minute' : '1 minute' unless include_seconds
        case seconds
          when 0..4   then 'less than 5 seconds'
          when 5..9   then 'less than 10 seconds'
          when 10..19 then 'less than 20 seconds'
          when 20..39 then 'half a minute'
          when 40..59 then 'less than a minute'
          else             '1 minute'
        end

      when 2..44           then "#{minutes} minutes"
      when 45..89          then 'about 1 hour'
      when 90..1439        then "about #{(minutes.to_f / 60.0).round} hours"
      when 1440..2879      then '1 day'
      when 2880..43199     then "#{(minutes / 1440).round} days"
      when 43200..86399    then 'about 1 month'
      when 86400..525599   then "#{(minutes / 43200).round} months"
      when 525600..1051199 then 'about 1 year'
      else                      "over #{(minutes / 525600).round} years"
    end
  end
end
end
