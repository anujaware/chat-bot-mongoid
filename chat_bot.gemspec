$:.push File.expand_path("../lib", __FILE__)

# Maintain your gem's version:
require "chat_bot/version"

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = "chat_bot"
  s.version     = ChatBot::VERSION
  s.authors     = ["Anuja Ware"]
  s.email       = ["anuja@joshsoftware.com"]
  s.homepage    = "https://github.com/anujaware/chat-bot-mongoid.git"
  s.summary     = "ChatBot"
  s.description = "Create decision tree of dialogues and options to chat with user i.e. predefined set of dialogue and options."
  s.license     = "MIT"

  s.files = Dir["{app,config,db,lib}/**/*", "MIT-LICENSE", "Rakefile", "README.rdoc"]
  s.test_files = Dir["test/**/*"]

  s.add_dependency "rails", "~> 4.2"
  s.add_dependency "mongoid", "~> 4.0"
  s.add_dependency "haml-rails", "~>0.9"
end
