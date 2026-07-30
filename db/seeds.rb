Dir[Rails.root.join("db/seeds/*.rb")].sort.each { |file| require file }
