Feature: viewer
  In order to experience content directly
  As a visitor
  I want to see an image of the content, zoomable if possible

  Scenario: Show the reference image
    Given I am on the document page for id sample_books_2_1
    When I follow "viewer"
    Then I should see the reference image "http://nyx.uky.edu/dips/sample_books_2/data/0001/0001.jpg"

  Scenario: Preserve view menu
    Given I am on the document page for id sample_books_2_1
    When I follow "viewer"
    Then I should see "viewer"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Pagination, existence
    Given I am on the viewer page for id sample_books_2_1
    Then I should see "2"
    And I should see "3"
    And I should see "4"

  Scenario: Pagination, function
    Given I am on the viewer page for id sample_books_2_1
    When I follow "3"
    Then I should be on the viewer page for id sample_books_2_3

  Scenario: Show an oral history
    Given I am on the document page for id sample_oral_history
    When I follow "viewer"
    Then I should see "Start now, start now"
