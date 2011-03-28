Feature: viewer
  In order to experience content directly
  As a visitor
  I want to see an image of the content, zoomable if possible

  Scenario: Show the reference image
    Given I am on the document page for id sample_aip_1
    When I follow "viewer"
    Then I should see the reference image "http://nyx.uky.edu/dips/sample_aip/data/0001/0001.jpg"

  Scenario: Preserve view menu
    Given I am on the document page for id sample_aip_1
    When I follow "viewer"
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"
