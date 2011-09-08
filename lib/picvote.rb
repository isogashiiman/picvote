require 'sinatra'
require 'haml'
require 'cgi'
require 'dm-migrations'
require 'dm-core'
require 'database'
require 'helpers'
require 'omniauth'
require 'digest/sha2'

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

  def just_liked?
    session[:liked]
  end

  def just_unliked?
    session[:unliked]
  end

  def voting_stats
    def rows_to_hash(rows) Hash[*rows.map { |row| _ = *row } .flatten] end
    def query(q) User.repository.adapter.select q end
    data = {}
    data[:per_user] = rows_to_hash query(
      'select u.name, count(v.user_id) as number from votes v
      join users u on u.id = v.user_id group by u.id')
    data[:votes_count] = rows_to_hash query(
      'select number, count(pic_id) from (
      select count(v.pic_id) as number, p.id as pic_id from votes v
      join pics p on p.id = v.pic_id group by p.id
      ) group by number')
    data[:votes_count][0] = query(
      'select count(1) from (select id from pics except
      select p.id from votes v join pics p on p.id = v.pic_id group by p.id)'
    )[0]
    data
  end
end

before do
  authorise current_user.uid if current_user
  redirect '/' unless trying_to_authenticate? or current_user
end

after do
  [:liked, :unliked].each do |key|
    session.delete key unless session[key].to_i == request.hash
  end
end

get '/' do
  pics = Pic.all(:order => :time)
  pics_by_days = pics.reduce [[[]], pics.first] do |acc, curr|
    coll, prev = *acc
    coll << [] unless curr.time.same_day_as prev.time
    coll.last << curr
    [coll, curr]
  end .first
  haml :main, :locals => { :pics_by_days => pics_by_days }
end

get /^\/img\/(.*\.jpg)$/i do |name|
  Pic.has_to_exist name.decode
  data = File.read "pics/#{name.decode}"
  content_type 'image/jpeg'
  cache_control :private
  etag Digest::SHA256.hexdigest data
  data
end

get /\/(.*\.jpg)$/i do |name|
  haml :pic, :locals => { :pic => Pic.first(:name => name.decode) }
end

post /\/(.*\.jpg)\/comment$/i do |name|
  halt if params[:text].empty?
  pic = Pic.first(:name => name)
  Comment.create! :text => params[:text], :user => current_user, :pic => pic,
    :time => Time.now
  redirect "/#{pic.url_name}"
end

get /\/(.*\.jpg)\/vote$/i do |name|
  pic = Pic.first(:name => name) or return 'No such picture.'
  Vote.first_or_create :user => current_user, :pic => pic
  session[:liked] = request.hash
  redirect "/#{pic.next.url_name}"
end

get /\/(.*\.jpg)\/unvote$/i do |name|
  pic = Pic.first(:name => name) or return 'No such picture.'
  Vote.first(:user => current_user, :pic => pic).destroy!
  session[:unliked] = request.hash
  redirect "/#{pic.next.url_name}"
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

get '/stats' do
  haml :stats, :locals => { :stats => voting_stats }
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
