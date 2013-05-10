require './API'
require 'mongoid'
Mongoid.load!("./mongoid.yml")

run API