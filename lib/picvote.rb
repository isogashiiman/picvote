require 'sinatra'
require 'haml'
require 'cgi'
require 'dm-migrations'
require 'dm-core'
require 'database'
require 'helpers'
require 'omniauth'

helpers do
  def current_user
    @current_user ||= User.first :uid => session[:uid]
  end

  def trying_to_authenticate?
    request.path == '/' or request.path.include? '/auth/google'
  end
end

before do
  redirect '/' unless trying_to_authenticate? or current_user
end

get '/' do
  haml :main, :locals => { :pics => Pic.all(:order => :time) }
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
  pic = Pic.first(:name => name) or return 'No suck picture.'
  Vote.first_or_create :user => current_user, :pic => pic
  redirect "/#{pic.next.name}"
end

get /\/(.*\.jpg)\/unvote$/i do |name|
  pic = Pic.first(:name => name) or return 'No suck picture.'
  Vote.first(:user => current_user, :pic => pic).destroy!
  redirect "/#{pic.next.name}"
end

get '/auth/google/callback' do
  auth = request.env['omniauth.auth']
  uid = auth['uid']
  raise 'Login failed' unless User.first_or_create :uid => uid,
    :name => auth['user_info']['name'] || uid
  session[:uid] = uid
  redirect '/'
end

get '/sign_out' do
  session.delete :uid
  redirect '/'
end

configure do
  use OmniAuth::Strategies::Google, 'anonymous', 'anonymous'
  enable :sessions
  %w(views public).each { |dir| set dir, File.dirname(__FILE__) + '/../' + dir }
  Database.setup
end
