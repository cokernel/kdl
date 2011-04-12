Feature: details
  In order to learn more about content
  As a visitor
  I want to see basic metadata about the content

  Scenario: Show the details view
    Given I am on the document page for id xt74qr4nkd58_1
    When I follow "details"
    Then I should see "Creator:"
    And I should see "Publication date:"
    And I should see "Date digitized:"
    And I should see "Description:"
    And I should see "Format:"
    And I should see "Identifier:"
    And I should see "Language:"
    And I should see "Publisher:"
    And I should see "Finding aid:" at most 1 time
    And I should see "Relation:" at most 1 time
    And I should see "Repository:"
    And I should see "Subject:" at least 0 times
    And I should see "Title:"
    And I should see "Type:"

  Scenario: Finding aid available
    Given I am on the document page for id sample_collections_folder_level_1_1_1_1
    When I follow "details"
    Then I should see "Finding aid:"

  Scenario: Metadata record
    Given I am on the details page for id xt74qr4nkd58_1
    Then I should see a "dt" element containing "Metadata record:"
    And I should see "xt74qr4nkd58/data/mets.xml"

  Scenario: Preserve view menu
    Given I am on the details page for id xt74qr4nkd58_1
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Preserve page number
    Given I am on the document page for id xt74qr4nkd58_1
    And I follow "3"
    And I follow "details"
    When I follow "viewer"
    Then I should be on the viewer page for id xt74qr4nkd58_3
