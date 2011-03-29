Feature: viewer
  In order to experience content textually
  As a visitor
  I want to see the text for a page

  Scenario: Show the text view
    Given I am on the document page for id sample_aip_1
    When I follow "text"
    Then I should see "READ AUGUST 15, 1907, AT THE DEDI-"

  Scenario: Preserve view menu
    Given I am on the document page for id sample_aip_1
    When I follow "text"
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Pagination, existence
    Given I am on the text page for id sample_aip_1
    Then I should see "2"
    And I should see "3"
    And I should see "4"

  Scenario: Pagination, function
    Given I am on the text page for id sample_aip_1
    When I follow "3"
    Then I should be on the text page for id sample_aip_3
