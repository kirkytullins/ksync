class Checker
	attr_reader :sp, :perms_h
	def initialize x,y
		@sp = [(0..x-1).map{|x|x},(0..y-1).map{|x|x}].flatten.permutation(2).map(&:join).uniq
	end	

	def get_permutations p_list
		@perms_h = {}
		p_list.each do |tuple|
			@perms_h[tuple] = sp.permutation(tuple).map(&:join).uniq.size
		end
	end

end

# main script

x,y = eval ARGV[0]

perm=eval ARGV[1]

puts ""
ch = Checker.new x,y
ch.get_permutations perm
ch.perms_h.each do |k,v|
	puts "permutations for (#{k} => #{v}	"
end