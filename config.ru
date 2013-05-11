require './API'
require 'mongoid'
Mongoid.load!("./mongoid.yml")

#require './newrelic'
#NewRelic::Agent.manual_start

run API