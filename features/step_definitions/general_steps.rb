Then /I should see "(.*)" (at least|at most|exactly) (.*) times?$/i do |target, comparator, expected_num|
  actual_num = response.body.split(target).length - 1
  case comparator
  when "at least"
    actual_num.should >= expected_num.to_i
  when "at most"
    actual_num.should <= expected_num.to_i
  when "exactly"
    actual_num.should == expected_num.to_i
  end
end
