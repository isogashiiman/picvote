require 'dm-core'

class Pic
  include DataMapper::Resource
  property :id,  Serial
  property :name, String, :length => 20, :unique_index => true,
    :required => true
  property :time, DateTime, :required => true, :index => true
  has n, :votes
  has n, :users, :through => :votes
  has n, :comments

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

  def Pic.with_votes_count(num)
    # This can be achieved in a more efficient way.
    repository.adapter.select('select p.id from votes v
    join pics p on p.id = v.pic_id group by p.id having count(v.pic_id) >= ' +
    num.to_i.to_s).map { |id| Pic.first :id => id } .sort do |x, y|
      x.time <=> y.time
    end
  end
end

class User
  include DataMapper::Resource
  property :id,  Serial
  property :uid, String, :length => 40, :unique_index => true,
    :required => true
  property :name, String, :length => 40, :required => true
  has n, :votes
  has n, :users, :through => :votes
end

class Vote
  include DataMapper::Resource
  belongs_to :pic, :key => true
  belongs_to :user, :key => true
end

class Comment
  include DataMapper::Resource
  property :id,  Serial
  property :text, Text, :length => 500, :required => true
  property :time, DateTime, :required => true, :index => true
  belongs_to :user
  belongs_to :pic
end

module Database
  def self.setup
    DataMapper::Logger.new($stderr, :info)
    DataMapper.setup(:default, ENV['DATABASE_URL'])
    DataMapper.auto_upgrade!
    fill_db_with_pics unless Pic.any?
  end

  def self.voting_stats
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

  private

  def self.fill_db_with_pics
    require 'exifr'
    pics = Dir.glob 'pics/**/*.{jpg,JPG}'
    pics.each_with_index do |name, index|
      STDERR.write "\rFilling db with pics... #{index + 1}/#{pics.count}"
      exif = EXIFR::JPEG.new name
      name.sub! /^pics\//, ''
      Pic.create!(:name => name, :time => exif.date_time_original)
    end
    STDERR.puts " OK"
  end

  def self.rows_to_hash(rows)
    Hash[*rows.map { |row| _ = *row } .flatten]
  end

  def self.query(q)
    User.repository.adapter.select q
  end
end
