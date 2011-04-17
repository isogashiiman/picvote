here = File.expand_path(File.dirname __FILE__)
$:.concat [here, here + '/exifr/lib']
require 'vote'
run Sinatra::Application
