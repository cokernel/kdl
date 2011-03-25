Feature: view menu
  In order to experience the same content in multiple ways
  As a visitor
  I want to see a view menu

  Scenario: Show view menu
    Given I am on the document page for id sample_aip_1
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"
