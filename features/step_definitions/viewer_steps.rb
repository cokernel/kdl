Then /^I should see the reference image "(\S+)"$/ do |src|
  response.should have_tag("img[src=#{src}]")
end
