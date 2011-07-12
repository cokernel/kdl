Feature: thumbs
  In order to get context for an image in a paged document
  As a visitor
  I want to see thumbnails of that page and nearby pages

  Scenario: Show the reference image
    Given I am on the document page for id sample_books_2_1
    When I follow "thumbs"
    Then I should see the thumbnail image "http://nyx.uky.edu/dips/sample_books_2/data/0001/0001_tb.jpg"
    And I should see the thumbnail image "http://nyx.uky.edu/dips/sample_books_2/data/0038/0038_tb.jpg"

  Scenario: Preserve view menu
    Given I am on the document page for id sample_books_2_1
    When I follow "thumbs"
    Then I should see "viewer"
    And I should see "thumbs"
    And I should see "details"
    And I should see "guide"
    And I should see "text"
    And I should see "pdf"

  Scenario: Pagination, existence
    Given I am on the thumbs page for id sample_books_2_1
    Then I should see "2"
    And I should see "3"
    And I should see "4"

  Scenario: Pagination, function
    Given I am on the thumbs page for id sample_books_2_1
    When I follow "3"
    Then I should be on the thumbs page for id sample_books_2_3
