# nanoc-tilt

This provides a filter that allows [Nanoc](https://nanoc.app) to process content via [Tilt](https://github.com/rtomayko/tilt).

## Installation

Add `nanoc-tilt` to the `nanoc` group of your Gemfile:

```ruby
group :nanoc do
  gem 'nanoc-tilt'
end
```

## Usage

Call the `:tilt` filter. For example:

```ruby
filter :tilt
```

Options passed to this filter will be passed on to the tilt filter. For example:

```ruby
filter :tilt, args: { escape: true }
```

```ruby
filter :tilt, args: { escape: false }
```
