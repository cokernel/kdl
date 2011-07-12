Then /^I should see the reference image "(\S+)"$/ do |src|
  response.should have_tag("img[src=#{src}]")
end

Then /^I should see the thumbnail image "(\S+)"$/ do |src|
  response.should have_tag("img[src=#{src}]")
end


Then /^I (should|should not) see an? "([^\"]*)" element containing "([^\"]*)"$/ do |bool,elem,content|
  if bool == "should"
    response.should have_selector("#{elem}",:content => content)
  else
    response.should_not have_selector("#{elem}",:content => content)
  end
end
