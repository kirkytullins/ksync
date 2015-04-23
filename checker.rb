class Checker
	attr_reader :mx, :my, :sections_hash, :route_hash
	def initialize x, y
		@mx = x
		@my = y
		@sections_hash = {}
		@route_hash = {}
		@cur_route = []
		@found = true 
	end

	def allowed? x, y 
		return false if x < 0 || y < 0 || x > @mx-1 || y > @my-1
		return true  
	end 

	def create_sections 
  	@sections = []
		(0..@mx-1).each do |x|
			(0..@my-1).each do |y|
				@sections << [x,y]
			end
		end
	end

	def get_all_sections
		create_sections
		(0..@mx-1).each do |x|
			(0..@my-1).each do |y|
				@sections_hash[[x,y]] = @sections.clone
				@sections_hash[[x,y]].delete [x,y]
			end
		end
	end
	
	def add_route xy
		@cur_route << xy
		if @route_hash[@cur_route] #exists 
			@cur_route.pop
			@found = false
		else
			@route_hash[@cur_route] = @cur_route
			@found = true 
		end	
	end

	def explore xy
		while @found
			(0..@mx-1).each do |x|
				(0..@my-1).each do |y|
					add_route [x,y] 
					explore [x,y]  
				end
			end		
		end
	end
end



# main script
ch = Checker.new 3,3 
ch.get_all_sections
ch.sections_hash.each do |k, v|
	puts "=> #{k}"
	puts "\t#{v}"
end
ch.explore [0,0]
ch.route_hash.each do |k,v|
	puts k
	puts "\t#{v}"
end
