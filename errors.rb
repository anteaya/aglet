module TwitterShoes
## ERRRRRORRRRRR HANDLLLLLINNNGG!! (say in the voice of Jon Lovitz as The Thespian)
module Errors
  def twitter_api(&block)
    begin
      timeout &block
    rescue *twitter_errors
    end
  end
  
  def timeout(seconds = 1, &block)
    Timeout.timeout(seconds, &block)
  end
  
  def twitter_errors
    [Timeout::Error, ::Twitter::CantConnect]
  end
  
  def twitter_down!
    fail_whale
    maintenance_message
    # video "http://sjc-v162.sjc.youtube.com/get_video?video_id=CWyjgYZvaj4"
  end
  
  def fail_whale
    image "http://static.twitter.com/images/whale.png",
      :width => 275, :height => 200, :margin => [0,0,0,5]
  end
  
  # Assuming that the maintenance page is up..
  def maintenance_message
    para *Hpricot(timeout { open("http://twitter.com") }).at("#content").
      to_s.scan(/>([^<]+)</).flatten. # XXX poor man's "get all descendant text nodes"
      reject { |x| x =~ /^\s*$/ }.    # except stuff that is just whitespace
      map { |x| x.squeeze(" ").strip }.join(" ")
  rescue Timeout::Error, OpenURI::HTTPError
    para "Twitter is down down down, probably just over capacity right now.",
      "Try again soon!"
  end
end
end
