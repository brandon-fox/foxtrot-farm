# Open item: domain ownership is unconfirmed (see README)
Feature: Custom domain

  Scenario: foxtrot.farm points at the site
    Given foxtrot.farm is registered to the business
    When CNAME.pending is renamed to CNAME and DNS points at GitHub Pages
    Then https://foxtrot.farm serves this page over HTTPS
