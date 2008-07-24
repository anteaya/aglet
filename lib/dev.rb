module TwitterShoes
### SOME STUFF FOR LOCAL DEVELOPMENT!
module Dev
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
end
end
