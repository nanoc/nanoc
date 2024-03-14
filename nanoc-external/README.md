# nanoc-external

This provides a filter that allows [Nanoc](https://nanoc.app) to process content by executing an external program.

## Installation

Add `nanoc-external` to the `nanoc` group of your Gemfile:

```ruby
group :nanoc do
  gem 'nanoc-external'
end
```

## Usage

Call the `:external` filter and pass the command to execute as the `:exec` argument. For example:

```ruby
filter :external, exec: 'wc'
```

The external command must receive input from standard input (“stdin”) and must send its output to standard out (“stdout”).

Options passed to this filter will be passed on to the external command. For example:

```ruby
filter :external, exec: 'multimarkdown', options: %w(--accept --mask --labels --smart)
```

You can also pass the full path of the executable:

```ruby
filter :external, exec: '/opt/local/bin/htmlcompressor'
```
