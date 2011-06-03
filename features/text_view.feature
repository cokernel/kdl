Feature: viewer
  In order to experience content textually
  As a visitor
  I want to see the text for a page

  Scenario: Show the text view
    Given I am on the document page for id sample_books_1_7
    When I follow "text"
    Then I should see "ADVENTURES O F Colortel DANIEL BOON"

  Scenario: Preserve view menu
    Given I am on the document page for id sample_books_1_7
    When I follow "text"
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Pagination, existence
    Given I am on the text page for id sample_books_1_7
    Then I should see "1"
    And I should see "6"
    And I should see "8"

  Scenario: Pagination, function
    Given I am on the text page for id sample_books_1_7
    When I follow "5"
    Then I should be on the text page for id sample_books_1_5

  Scenario: Don't link to missing text
    Given I am on the document page for id sample_collections_item_level_1_1_1   
    Then I should see "text"
    And I should not see a "a" element containing "text"

  Scenario: Handle lack of text
    Given I am on the text page for id sample_collections_item_level_1_1_1
    Then I should see "Text not available."
