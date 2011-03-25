Feature: viewer
  In order to experience content directly
  As a visitor
  I want to see an image of the content, zoomable if possible

  @wip
  Scenario: Show the reference image
    Given I am on the document page for id sample_aip_1
    When I follow "viewer"
    Then I should see the reference image for id sample_aip_1
