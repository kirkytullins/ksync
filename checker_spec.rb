require 'rspec'
$LOAD_PATH.unshift File.dirname(__FILE__)
require 'checker'
RSpec.describe "Checker" do

  before(:all) do 
  	@ch = Checker.new 3,3
		@n_list = [9, 72, 504, 3024, 15120, 60480, 181440, 362880] 
  end 

	it "initializes" do 
		expect(@ch).not_to be(nil)
	end

	it "gets correct sp" do 
		expect(@ch).not_to be(nil)
		expect(@ch.sp.size).to be(9)
	end

	it "gets correct n-tuples possible permutations" do 
		1.upto(8).each do |n| 
			expect(@ch.get_perms(n)).to be(@n_list[n-1])
		end
	end

	it "gets all existing permutations total size" do
		expect(@ch.perms_h.values.inject(&:+)).to be(@n_list.inject(&:+))
	end

	it "gets all possible routes starting from xy point" do 
		i = @ch.get_sp_index(0,0)
		expect(i).not_to be(nil)

	end

end
