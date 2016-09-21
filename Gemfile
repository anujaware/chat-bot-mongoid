source 'https://rubygems.org'

# Declare your gem's dependencies in chat_bot.gemspec.
# Bundler will treat runtime dependencies like base dependencies, and
# development dependencies will be added by default to the :development group.
gemspec

# Declare any dependencies that are still in development here instead of in
# your gemspec. These might include edge Rails or gems from your path or
# Git. Remember to move these dependencies to your gemspec before releasing
# your gem to rubygems.org.

# To use a debugger
# gem 'byebug', group: [:development, :test]


gem 'mongoid', '~>5.1.4'
gem 'haml-rails'
gem 'mongoid-slug'
gem 'bootstrap-sass', '~> 3.3.6'
gem 'sass-rails', '>= 3.2'
gem 'jquery-rails'
gem 'bootstrap-select-rails'
gem 'bootstrap_form'

group :test do
  gem 'minitest-line'
  gem 'mongoid-fixture_set'
  gem 'faker'
  gem 'shoulda', '~> 3.5'
  gem 'shoulda-matchers', '~> 2.0'

##TODO Required for mintest matchers to test associations
  gem 'mongoid-minitest'
  gem 'minitest-matchers'

  gem 'database_cleaner'
end
