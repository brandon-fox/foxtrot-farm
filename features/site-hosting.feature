# Decision: docs/decisions/0001-site-hosting.md
Feature: Hosting switch

  Scenario Outline: The site starts doing business
    Given the site is hosted on GitHub Pages
    When <trigger>
    Then move the same files to Cloudflare Pages
    And put any order form or checkout on an outside service, not hand-built card handling

    Examples:
      | trigger                                          |
      | it takes online orders, payments or bookings     |
      | it collects form submissions from customers      |
      | it needs server-side code or a database          |
      | the repo needs to be private                     |
      | traffic nears 100 GB a month                     |

  Scenario: Nothing has changed
    Given the site is still a static landing page
    When the 2027 season opens
    Then stay on GitHub Pages
