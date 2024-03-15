# nanoc-org-mode

This provides a filter that allows [Nanoc](https://nanoc.app) to process content via [Org Mode](https://orgmode.org/).

## Installation

Add `nanoc-org-mode` to the `nanoc` group of your Gemfile:

```ruby
group :nanoc do
  gem 'nanoc-org-mode'
end
```

## Usage

Call the `:org_mode` filter. For example:

```ruby
filter :org_mode
```
