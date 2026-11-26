# 0001: Site hosting

- Status: Accepted
- Date: 2026-11-26
- Revisit: when any switch trigger below fires, or before the 2027 season opens

## Question

Where should the Foxtrot Farm and Firewood website be hosted?

## Why it needs a decision

The site is a static landing page today. It will probably need ordering later. The owner's rules: no paid tiers, smallest solution, keep the specs in the repo as the source of truth.

## Inputs

- GitHub Pages hosts static HTML, CSS and JS only: no server code, database or form handling.
- GitHub Free needs a public repo to publish Pages.
- Limits: published site up to 1 GB; soft bandwidth limit of 100 GB a month; deployments time out after 10 minutes.
- GitHub's terms say Pages is "not intended for or allowed to be used as a free web-hosting service to run your online business", including an e-commerce site, and it shouldn't carry sensitive transactions such as passwords or card numbers.
- Source: https://docs.github.com/en/pages/getting-started-with-github-pages/github-pages-limits (read 2026-11-26).
- VERIFY: that Cloudflare Pages' free plan allows commercial sites, and what its current limits are.
- VERIFY: who owns foxtrot.farm (a custom domain is independent of the host).

## Options

1. **GitHub Pages (chosen).** Free, deploys on push, supports a custom domain and HTTPS, and keeps specs and site in one repo. Cons: static only, public repo, and its terms rule out running the business on it.
2. **Cloudflare Pages.** Free, static plus serverless functions, same git flow, supports a custom domain. Cons: a new account, and one more vendor. Plan-terms VERIFY.
3. **A hosted store platform.** Built-in ordering and payments. Cons: paid monthly, and the owner's no-paid-tiers rule.

## Decision

Stay on GitHub Pages while the site is a static landing page. Move to Cloudflare Pages when a switch trigger fires.

## Switch triggers

Feature: Hosting switch
  Scenario: The site starts doing business
    Given the site is hosted on GitHub Pages
    When it takes online orders, payments or bookings
    Or it collects form submissions from customers
    Or it needs server-side code or a database
    Or the repo needs to be private
    Or traffic nears 100 GB a month
    Then move the same files to Cloudflare Pages
    And put any order form or checkout on an outside service, not hand-built card handling

  Scenario: Nothing has changed
    Given the site is still a static landing page
    When the 2027 season opens
    Then stay on GitHub Pages

## Consequences

- Cost stays at zero apart from the domain.
- Moving later is low effort: the same static files, new DNS records and no rebuild.
