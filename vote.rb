require 'sinatra'
require 'dm-core'
require 'dm-migrations'

class Pic
  include DataMapper::Resource
  property :id,  Serial
  property :name, String, :length => 20, :unique_index => true,
    :required => true
  property :time, DateTime, :required => true, :index => true
  has n, :votes
  has n, :users, :through => :votes

  def previous
    Pic.first :order => :time.desc, :time.lt => time
  end

  def next
    Pic.first :order => :time.asc, :time.gt => time
  end

  def Pic.has_to_exist(name)
    throw 'No such pic' if Pic.first(:name => name).nil?
  end

  def voted_by?(username)
    if username.is_a? String
      users.include? User.first(:login => username)
    else
      throw 'A string was expected'
    end
  end
end

class User
  include DataMapper::Resource
  property :id,  Serial
  property :login, String, :length => 20, :unique_index => true,
    :required => true
end

class Vote
  include DataMapper::Resource
  belongs_to :pic, :key => true
  belongs_to :user, :key => true
end

def redirect_back
  redirect request.env['HTTP_REFERER']
end

get '/' do
  erb :main, :locals => { :pics => Pic.all(:order => :time) }
end

post '/login' do
  session[:username] = params[:username]
  redirect_back
end

get '/logout' do
  session.delete :username
  redirect_back
end

get '/img/:name' do |name|
  Pic.has_to_exist name
  content_type 'image/jpeg'
  File.read("pics/#{name}")
end

get /\/(.*\.jpg)$/i do |name|
  erb :pic, :locals => { :pic => Pic.first(:name => name) }
end

get /\/(.*\.jpg)\/vote$/i do |name|
  return 'Please introduce yourself before voting.' unless session[:username]
  pic = Pic.first(:name => name) or return 'Nie ma takiego obrazka'
  user = User.first_or_create(:login => session[:username])
  Vote.first_or_create(:user => user, :pic => pic)
  redirect "/#{pic.next.name}"
end

def fill_db_with_pics
  require 'exifr'
  pics = Dir.glob('pics/*.{jpg,JPG}')
  n = 0
  pics.each do |name|
    STDERR.write "\rFilling db with pics... #{n += 1}/#{pics.count}"
    exif = EXIFR::JPEG.new name
    name.sub! /pics\//, ''
    Pic.create!(:name => name, :time => exif.date_time)
  end
  STDERR.puts " OK"
end

configure do
  enable :sessions
  DataMapper::Logger.new($stderr, :info)
  DataMapper.setup(:default, ENV['DATABASE_URL'])
  DataMapper.auto_upgrade!
  fill_db_with_pics unless Pic.any?
end
