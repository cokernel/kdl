Then /^I should see the reference image "(\S+)"$/ do |href|
  response.should have_tag("img[href=#{href}]")
end
