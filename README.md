# Common

[![Maintainability](https://api.codeclimate.com/v1/badges/33e4381f281a664abc06/maintainability)](https://codeclimate.com/repos/5c35fe8b5736ed355f0015c7/maintainability)
[![Test Coverage](https://api.codeclimate.com/v1/badges/33e4381f281a664abc06/test_coverage)](https://codeclimate.com/repos/5c35fe8b5736ed355f0015c7/test_coverage)

A package of common controllers, concerns & authentication for the [React/Rails Shopify app](https://github.com/pemberton-rank/react-shopify-app). Used in production by the 100k user app: [Plug in SEO](https://apps.shopify.com/plug-in-seo).

## How to use

Reference the repo and a specific version in your Gemfile like this:

```
gem "pr-common", git: "https://github.com/pemberton-rank/common.git"
```

## Development
* create a branch of common
* create a branch of project X (the project which references common)
* use your local copy of common in project X (see the Gemfile)
* when you are finished with all of the work needed for common,
* add an entry to the CHANGELOG
* create a pull request
* when that pull request is approved and merged, update project X's gemfile to reference common master
* create a pull request for project X


