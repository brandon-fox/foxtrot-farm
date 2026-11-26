# Foxtrot Farm and Firewood

One-page landing site for Foxtrot Farm and Firewood. Static HTML, no build step, hosted free on GitHub Pages.

## Spec

Feature: Landing page
  Scenario: A visitor opens the site
    Given the site is published
    When a visitor opens it on a phone or desktop
    Then they see what the business is: firewood, a truck farm and a nursery
    And they see that it reopens for the 2027 season
    And no home address, phone number or personal email appears

Feature: Custom domain
  Scenario: foxtrot.farm points at the site
    Given foxtrot.farm is registered to the business
    When `CNAME.pending` is renamed to `CNAME` and DNS points at GitHub Pages
    Then https://foxtrot.farm serves this page over HTTPS

## Open items (VERIFY)

- Domain ownership: foxtrot.farm shows as registered, owner unknown. Rename `CNAME.pending` to `CNAME` only once the domain is confirmed ours.
- Location line ("Long Island, New York"): confirm it is fine to show.
- Contact method for 2027 (business email or form).
- Optional single link to the owner's portfolio site.

## Deploy

1. Push to the default branch.
2. Settings > Pages > Source: Deploy from a branch, `main`, `/ (root)`.
