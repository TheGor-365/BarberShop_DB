require 'rubygems'
require 'sinatra'
require 'sinatra/reloader'
require 'sqlite3'

# barber existz check method
#----------------------------

def is_barber_exists? db, barbername
  db.execute('SELECT * FROM Barbers WHERE barbername = ?', [barbername]).length > 0
end

# seed db (Barbers table)
#-------------------------

def seed_db db, barbers
  barbers.each do |barber|
    if !(is_barber_exists? db, barber)
      db.execute 'INSERT INTO Barbers (barbername) VALUES (?)', [barber]
    end
  end
end

# db initialization method
#--------------------------

def get_db
  db = SQLite3::Database.new 'barber.sqlite'
  db.results_as_hash = true
  return db
end

configure do
  db = get_db
  db.execute 'CREATE TABLE IF NOT EXISTS Users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT,
    phone TEXT,
    datestamp TEXT,
    barber TEXT,
    color TEXT
  )'

  db.execute 'CREATE TABLE IF NOT EXISTS Barbers (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    barbername TEXT
  )'

  seed_db db, ['Jessie Pinkman', 'Walter White', 'Gus Fring', 'Adam Sendler']
end

# log in / log out
#------------------

configure do
  enable :sessions
end

helpers do
  def username
    session[:identity] ? session[:identity] : 'Sign in'
  end
end

before '/secure/*' do
  unless session[:identity]
    session[:previous_url] = request.path
    @error = 'Need to be logged ' + request.path
    halt erb(:login_form)
  end
end

get '/login/form' do
  erb :login_form
end

post '/login/attempt' do
  session[:identity] = params['username']
  where_user_came_from = session[:previous_url] || '/secure/place'
  redirect to where_user_came_from
end

get '/logout' do
  session.delete(:identity)
  redirect to '/'
end

# About page
#------------

get '/about' do

  erb :about
end

get '/' do

  erb :index
end

# Users page (site admin zone)
#-------------------------------

get '/secure/place' do
  db = get_db

  @results = db .execute 'SELECT * FROM Users
  ORDER BY id DESC'

  erb :users
end

# before for Barbers get/POST
#------------------------------

before do
  db = get_db
  @barbers = db.execute 'SELECT * FROM Barbers'
end

# visit page (user zone)
#------------------------

get '/visit' do

  erb :visit
end

post '/visit' do
  @username = params[:username]
  @phone = params[:phone]
  @datetime = params[:datetime]
  @barber = params[:barber]
  @color = params[:color]
  @sign = params[:sign]

  hh = {
    username: 'Type your name',
    phone: 'Type your phone',
    datetime: 'Type your visiting date and time'
  }

  @error = hh.select { |key,_| params[key] == ''}.values.join(', ')

  if @error != ''
    return erb :visit
  end

  if @sign
    @message = "Thanks for sign #{@username}, we'll be waiting for you"
  end

  db = get_db
  db.execute 'INSERT INTO Users (username, phone, datestamp, barber, color)
  VALUES (?, ?, ?, ?, ?)', [@username, @phone, @datetime, @barber, @color]

  erb :visit
end
