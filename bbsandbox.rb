require 'sinatra'
require 'slim'
require 'digest/sha1'
require 'bb-ruby'
require 'ruby-bbcode'
require './bristle.rb'

@@engines = ['bb-ruby', 'ruby-bbcode', 'raw', 'bristle']

get '/' do
  @posts = list_posts
  @engines = @@engines
  slim :index
end

def show_create_page(engine)
  get "/#{engine}" do
    slim :input
  end
end

def get_post(engine)
  get "/#{engine}/:slug" do
    body = read_post params[:slug]
    @engine = 'bb-ruby'
    @slug = params[:slug]
    @other_engines = @@engines.select{|e| e != engine}
    @bbcode_output = exec_bbcode engine, body
    slim :output
  end
end

def exec_bbcode(engine, body)
  case engine
  when "bb-ruby"
    BBRuby.to_html body
  when "ruby-bbcode"
    RubyBBCode.to_html body
  when "bristle"
    Bristle.parse body
  when "raw"
    body
  else
    raise "unknown engine: #{engine}"
  end
end

def create_post(engine)
  post "/#{engine}" do
    slug = store_post request
    redirect to("#{engine}/#{slug}")
  end
end

def setup_dir
  begin
    Dir.mkdir "posts"
  rescue
  end
end

def slugify(title)
  title.downcase.strip.split(" ").join('-')
end

def store_post(request)
  setup_dir
  title = slugify(request["slug"])
  comment = request["comment"]
  File.write "posts/#{title}", comment
  title
end

def read_post(slug)
  file = File.open("posts/#{slug}", "r")
  file.read
end

def list_posts
  Dir.entries("posts").select{|entry| entry != '.' && entry != '..'}
end

@@engines.each do |engine|
  show_create_page engine
  get_post engine
  create_post engine
end

