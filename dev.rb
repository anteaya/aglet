module TwitterShoes
module Dev
  def update_fixture_file(timeline)
    File.open(timeline_fixture_path, "w+") { |f| f.puts timeline.to_yaml }
  end
  
  def timeline_fixture_path
    File.join Dir.pwd, "timeline.yml"
  end
  
  # return true for certain side effects.
  def testing_ui?
    # true
  end
end
end
