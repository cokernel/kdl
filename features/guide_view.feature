Feature: guide
  In order to learn more about the organization of content
  As a visitor
  I want to see a guide to a collection

  Scenario: Show the guide view
    Given I am on the document page for id sample_collections_folder_level_1_1_1_1
    When I follow "guide"
    Then I should be on the guide page for id sample_collections_folder_level_1_1_1_1
    And I should see "Cooper-Phillips family papers, 1839-1911, bulk 1857-1866"

  Scenario: Preserve view menu
    Given I am on the guide page for id sample_collections_folder_level_1_1_1_1
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Don't link to missing guide
    Given I am on the document page for id sample_books_1_1
    Then I should see "guide"
    And I should not see a "a" element containing "guide"

  Scenario: Handle lack of guide
    Given I am on the guide page for id sample_books_1_1
    Then I should see "Guide not available."
