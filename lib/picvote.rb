require 'sinatra'
require 'haml'
require 'cgi'
require 'dm-migrations'
require 'dm-core'
require 'database'
require 'helpers'

def redirect_back
  redirect request.env['HTTP_REFERER']
end

get '/' do
  haml :main, :locals => { :pics => Pic.all(:order => :time) }
end

post '/login' do
  session[:username] = params[:username]
  redirect_back
end

get '/logout' do
  session.delete :username
  redirect_back
end

get /^\/img\/(.*\.jpg)$/i do |name|
  Pic.has_to_exist name.decode
  content_type 'image/jpeg'
  File.read "pics/#{name.decode}"
end

get /\/(.*\.jpg)$/i do |name|
  haml :pic, :locals => { :pic => Pic.first(:name => name.decode) }
end

get /\/(.*\.jpg)\/vote$/i do |name|
  return 'Please introduce yourself before voting.' unless session[:username]
  pic = Pic.first(:name => name) or return 'No suck picture.'
  user = User.first_or_create(:login => session[:username])
  Vote.first_or_create(:user => user, :pic => pic)
  redirect "/#{pic.next.name}"
end

get /\/(.*\.jpg)\/unvote$/i do |name|
  return 'Please introduce yourself before voting.' unless session[:username]
  pic = Pic.first(:name => name) or return 'No suck picture.'
  user = User.first_or_create(:login => session[:username])
  Vote.first(:user => user, :pic => pic).destroy!
  redirect "/#{pic.next.name}"
end

configure do
  enable :sessions
  %w(views public).each { |dir| set dir, File.dirname(__FILE__) + '/../' + dir }
  Database.setup
end
