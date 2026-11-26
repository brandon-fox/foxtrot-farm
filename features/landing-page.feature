# Page: index.html
Feature: Landing page

  Scenario: A visitor opens the site
    Given the site is published
    When a visitor opens it on a phone or desktop
    Then they see what the business is: firewood, a truck farm and a nursery
    And they see that it reopens for the 2027 season
    And no home address, phone number or personal email appears
