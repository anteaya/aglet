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
    [Timeout::Error, Twitter::CantConnect]
  end
  
  def fail_status
    Twitter::Status.new do |s|
      s.text = "Twitter is over capacity. Timeline will continue to attempt to reload."
      s.user = fail_user
      s.created_at = Time.new
    end
  end
  
  def fail_user
    Twitter::User.new do |u|
      u.profile_image_url = "whale.png"
      u.name = "fail whale"
      u.screen_name = nil
      u.location = "an octopuses garden, in the shade"
      u.url = "http://blog.twitter.com"
      u.profile_background_color = fail_whale_orange
    end
  end
  
  def fail_whale
    image "whale.png",
      :width => 45, :height => 45, :margin => 5
  end
  
  # Assuming that the maintenance page is up..
  def maintenance_message
    para *Hpricot(timeout { open("http://twitter.com") }).at("#content").
      to_s.scan(/>([^<]+)</).flatten. # XXX poor man's "get all descendant text nodes"
      reject { |x| x =~ /^\s*$/ }.    # except stuff that is just whitespace
      map { |x| x.squeeze(" ").strip }.join(" ")
  rescue Timeout::Error, OpenURI::HTTPError
    para "Twitter is down down down, probably just over capacity right now. ",
      "Try again soon!"
  end
end
end
