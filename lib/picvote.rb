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

  def authorise(uid)
    if not settings.auth_list.empty? and not settings.auth_list.include? uid
      session.delete :uid
      halt 401, "You're not authorised. Sorry."
    end
  end
end

before do
  authorise current_user.uid if current_user
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
  pic = Pic.first(:name => name) or return 'No such picture.'
  Vote.first_or_create :user => current_user, :pic => pic
  redirect "/#{pic.next.name}"
end

get /\/(.*\.jpg)\/unvote$/i do |name|
  pic = Pic.first(:name => name) or return 'No such picture.'
  Vote.first(:user => current_user, :pic => pic).destroy!
  redirect "/#{pic.next.name}"
end

get '/auth/google/callback' do
  auth = request.env['omniauth.auth']
  uid = auth['uid']
  authorise uid
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
  begin
    File.open File.dirname(__FILE__) + '/../config/authorised.txt', 'r' do |f|
      set :auth_list, f.readlines.map { |line| line.chomp }
    end
  rescue Errno::ENOENT
    set :auth_list, []
  end
end
