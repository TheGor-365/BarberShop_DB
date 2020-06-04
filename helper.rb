require 'sqlite3'

db = SQLite3::Database.new 'barber.sqlite'
db.results_as_hash = true

db.execute 'select * from Users' do |row|
  puts "#{row['username']} come at #{row['datestamp']}"
  puts '-------------------------------------'
end
