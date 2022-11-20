# nanoc-dart-sass

This provides a filter that allows [Nanoc](https://nanoc.app) to process content via [Dart Sass](https://sass-lang.com/dart-sass).

This filter offers similar functionality to Nanoc’s built-in `:sass` filter. The built-in `:sass` filter, however, uses the [Ruby Sass](https://sass-lang.com/ruby-sass) implementation, which has reached end of life.

## Installation

Add `nanoc-dart-sass` to the `nanoc` group of your Gemfile:

```ruby
group :nanoc do
  gem 'nanoc-dart-sass'
end
```

## Usage

Call the `:dart_sass` filter. For example:

```ruby
filter :dart_sass
```

Options passed to this filter will be passed on to Dart Sass. For example:

```ruby
filter :dart_sass, syntax: 'scss'
```

```ruby
filter :dart_sass, syntax: 'scss'
```
