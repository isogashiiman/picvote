$: << File.join(File.expand_path(File.dirname __FILE__), 'lib')
require 'picvote'
run Sinatra::Application
