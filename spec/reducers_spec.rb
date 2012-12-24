require_relative 'spec_helper'

require "reducers"

describe Reducers do
 it "can be created" do
   Reducers.new.must_be_instance_of Reducers
 end
end
