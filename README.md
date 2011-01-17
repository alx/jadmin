# Jadmin

Jekyll administration tool in Rails 3

## Requirements

* Ruby bundler
* [Jekyll](http://www.jekyllrb.com)
* Apache server with vhost to _/var/www/jekyll.website.org/_site/_

## Install

    git clone 
    bundle install
    rails s

## Config

### Jekyll-Git repository

This install suppose your Jekyll folder is managed by Git.

You need to configure your current Jekyll folder in _config/environment.rb_ :

    config.jekyll_folder = '/var/www/jekyll.website.org'

### Basic Authentification

Because you don't want everyone to create/edit/delete posts, you might want to configure a basic auth on these actions.

Edit _config/auth_config.yml_ with the login/password you'll use to create/edit/delete posts.

### post-update git hook

In your git repository, update your post-update hook to automaticly update your jekyll website at every post update:

    $ cat /home/git/repositories/jekyll.git/hooks/post-update
    unset GIT_DIR && cd /var/www/jekyll.website.org && git pull && /var/lib/gems/1.8/bin/jekyll
    echo "finished deployment"
