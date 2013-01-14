require 'ksync'
require 'aspector'
require 'pry'


# class for evaluating AOP
class TestAspect  < Aspector::Base

  # all the methods regular expression
  ALL_METHODS = /.*/

  around ALL_METHODS, :except => [:class, :ll, :all_h], :aspect_arg => true, :method_arg => true do |aspect, method, proxy, *args, &block|
    class_method = "#{self.class}.#{method} "

    mh = aspect.options[:mh]
    if !mh[class_method]
      mh[class_method] = 1
    else
      mh[class_method] += 1
    end
    puts "(#{mh[class_method]})Entering #{class_method}: #{args.join(',')}" if aspect.options[:logit]
    result = proxy.call *args, &block
    puts "Exiting  #{class_method}: #{result}" if aspect.options[:logit]
    result
  end

end



#TestAspect.apply KSync, :method => [:do_copy, :do_sync, :create_hash]
m_h={}
TestAspect.apply(KSync, :mh => m_h, :logit => false)

a=KSync.new(:src => 'c:/dev-cpp', :dst => 'c:/dev-cp2')
a.do_sync

m_h.each do |k,v|
  puts "#{k} : #{v}"
end

