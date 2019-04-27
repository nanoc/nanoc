# Guard::Nanoc

This is a guard for [nanoc](https://nanoc.ws/).

`Guard` is a framework for listening to filesystem changes and acting upon them. `Guard::Nanoc` is a plugin for Guard that recompiles Nanoc sites on changes.

## Installation

Add the `guard-nanoc` gem inside the `nanoc` group to your application's Gemfile:

    group :nanoc do
      gem 'guard-nanoc'
    end

Unless your Gemfile already specifies a web server, you'll need one as well:

    gem 'adsf'

Lastly, ensure that Nanoc is at least version 4.3:

    gem 'nanoc', '~> 4.3'

And then execute:

    $ bundle

## Usage

Enter the Nanoc site directory for which you want to use guard-nanoc. Create a Guardfile using `guard init`:

    $ bundle exec guard init nanoc

Then run:

    $ bundle exec nanoc live

This will start a web server, like `nanoc view` would, and watch for changes
to the site in the background, like `guard start` would. Whenever you change
a file in the Nanoc site directory now, the site will be recompiled!
Visit `http://localhost:3000` in browser to see it. (In some cases, the port
number might not be `3000`; check what `nanoc live` prints to find out
the actual port number.)

After editing and saving a file, `nanoc live` will recompile the site, but it
is necessary to reload the page in the browser in order to see the new content
that is served by `nanoc live`.
