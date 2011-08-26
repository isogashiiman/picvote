require 'dm-core'

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

  def url_name
    CGI.escape name
  end
end

class User
  include DataMapper::Resource
  property :id,  Serial
  property :uid, String, :length => 40, :unique_index => true,
    :required => true
  property :name, String, :length => 40, :required => true
end

class Vote
  include DataMapper::Resource
  belongs_to :pic, :key => true
  belongs_to :user, :key => true
end

module Database
  def self.setup
    DataMapper::Logger.new($stderr, :info)
    DataMapper.setup(:default, ENV['DATABASE_URL'])
    DataMapper.auto_upgrade!
    fill_db_with_pics unless Pic.any?
  end

  private

  def self.fill_db_with_pics
    require 'exifr'
    pics = Dir.glob 'pics/**/*.{jpg,JPG}'
    pics.each_with_index do |name, index|
      STDERR.write "\rFilling db with pics... #{index + 1}/#{pics.count}"
      exif = EXIFR::JPEG.new name
      name.sub! /^pics\//, ''
      Pic.create!(:name => name, :time => exif.date_time)
    end
    STDERR.puts " OK"
  end
end
