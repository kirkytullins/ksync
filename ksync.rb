#--
# Copyright (c) 2012 Kiriakos ADONIADIS kiriakos.adoniadis@gmail.com
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following conditions:
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
#++
#
# This class does a sync between source and destination folders 
#
# The comparison is based on : 
#   a) size & date by default and optionally on 
#   b) sha1 hash of the source and destination files
#
# NOTE: If any files in the destination folder have changed and the -u option (use hash) is not 
# specified, then these changes will NOT be detected. This is a fast backup solution and presumes
# that the destination never changes.
# This algo has been tested with 
# TODO: change the Find.find + hash based mechanism into a more robust one not limited by hash size and 
# consequently memory size
#

require 'fileutils'
require 'digest'
require 'optparse'
require 'ostruct'
require 'find'

class KSync

  SSIZE_I=0
  CTIME_I=1
  MTIME_I=2

  attr_accessor :src_path, :dst_path, :options, :all_h, :ll, :changes
  def initialize()        
       
    @all_h={}
    
    @changes = false    
    @options = OpenStruct.new    
    @options.real_copy = true 
    @options.use_hash = false 
    @options.verbose = 0
    @o = OptionParser.new
    @o.banner = "Usage: #{$0} [options] source_folder destination_folder"
    @o.on('-d', '--dry_run', 'dry run (default : do the real copy - no dry run)') { |s| @options.real_copy = false }    
    @o.on('-v', '--verbosity=value', 'The level of verbosity (1..3) (default = 0 : very silent)') { |s| @options.verbose = s.to_i }    
    @o.on('-u', '--use_hash', 'use hash calculation (default : dont use hash)') { |s| @options.use_hash = true }    
    @o.on('-h', '--help') { message }    
    
    @o.parse! 
    if @options.verbose
      puts "=== Active Options === "
      puts "  verbose: #{@options.verbose}"
      puts "real_copy: #{@options.real_copy}"
      puts " use_hash: #{@options.use_hash}"
    end      
    message if !ARGV[0] || !ARGV[1]       
    @ll = [ARGV[0],ARGV[1]]    
    create_hash    
  end

  def do_sync    
    src=0    
    dst=1    
    # browse source hash to detect new and changed files
    @all_h[ll[src]].each do |k,v|
      #puts k
      src_fp = File.join(@ll[src],k)
      dst_fp = File.join(@ll[dst],k)
      if !@all_h[@ll[dst]][k]
        puts "N: #{k}" if @options.verbose > 0 
        do_copy(src_fp, dst_fp, v) if @options.real_copy
        @changes = true
      else
        if !File.directory?(File.join(@ll[src],k))
          if !same?(src_fp, dst_fp, v, all_h[@ll[dst]][k])
            puts "C: #{k}" if @options.verbose > 0 
            do_copy(src_fp, dst_fp, v) if @options.real_copy 
            @changes = true
          end
        end   
      end   
    end  
    # browse destination hash to detect obsolete files
    @all_h[ll[dst]].each do |k,v|
      if !all_h[ll[src]][k] 
        dst_fp = File.join(ll[dst],k)
        puts "D: #{dst_fp}" if @options.verbose > 0 
        do_delete dst_fp if @options.real_copy
        @changes = true
      end  
    end  
    puts "there were changes" if @changes
    puts "nothing changed" if !@changes
    
  end  
  
  def get_hash(in_file)    
    if !File.exists?(in_file)
      puts "ERR: inexistent file : #{in_file}"
      return nil
    end  
    sha1 = Digest::SHA1.new
    begin
      File.open(in_file) do |file|
        buffer = ''
        # Read the file 512 bytes at a time
        while not file.eof
          file.read(512, buffer)
          sha1.update(buffer)
        end
      end
    rescue 
      puts "ERR: while calculating hash for : #{in_file}: (#{$!})"
      return nil
    end  
    return sha1.to_s
  end 

  def do_copy(src_fp, dst_fp, src)
    begin       
      if File.directory?(src_fp)
        file_op = "mkdir"
        FileUtils.mkdir_p dst_fp 
      else
        file_op = "cp"
        FileUtils.copy_file src_fp, dst_fp        
        # mtime = src[MTIME_I]
        # file_op = 'atime'
        # atime = src[CTIME_I]
        # file_op = 'utime'
        # sleep(0.1)
        # File.utime(atime, mtime, dst_fp)        
      end  
    rescue 
      puts "ERR: while copying (#{file_op}) [#{src_fp} to #{dst_fp}] : (#{$!})"
      return
    end    
  end

  def do_delete (dst_fp)
    begin 
      if File.exists?(dst_fp) 
        if File.directory?(dst_fp)
          file_op = 'remove_dir'
          FileUtils.remove_dir(dst_fp)
          # if Dir["#{dst_fp}/*"].size > 0 
            # puts "cannot delete non empty folder : (#{dst_fp})"
          # else
            # FileUtils.rmdir "#{dst_fp}"
          # end            
        else
          file_op = 'rm'
          FileUtils.rm dst_fp
        end          
      else
        puts "ERR: inexistent file/folder : #{dst_fp}"
      end      
    rescue 
      puts "ERR: (#{file_op}) for #{dst_fp} : (#{$!})"
    end
  end
  
  # if hash => also check hash if sizes are same
  def same?(src_fp, dst_fp, src, dst)
    size_ok = false
    date_ok = false   
    if src[SSIZE_I] == dst[SSIZE_I] # sizes are the same
      size_ok = true
 #     tdiff = src[CTIME_I] >= dst[CTIME_I] ? src[CTIME_I] - dst[CTIME_I] : dst[CTIME_I] - src[CTIME_I] 
      if dst[MTIME_I] - dst[MTIME_I]  >=  0                
        date_ok = true 
      else
        puts "DATE diff for #{src_fp} vs #{dst_fp}" if @options.verbose > 1
      end  
    else
      puts "SIZE diff for #{src_fp} vs #{dst_fp}" if @options.verbose > 1
    end    
    return false if !size_ok 
    return false if !date_ok 
    return false if !date_ok 
    return true if !@options.use_hash    
    h1 = get_hash(src_fp)
    h2 = get_hash(dst_fp)
    if h1 && h2
      if h1 != h2   
        puts "SHA1 diff for #{src_fp} vs #{dst_fp}" if @options.verbose > 1
        return false 
      end  
      return true
    else
      exit
    end  
  end
  
  def message 
    puts @o
    exit
  end
  
  def create_hash    
    @ll.each do |prefix|
      puts "creating hash for #{prefix}" if @options.verbose > 1 
      @all_h[prefix] = {}
      cnt = 0 
      FileUtils.mkdir_p prefix if !File.exists?(prefix)        
      Find.find(prefix).each do |f|
        next if prefix == f
        ff = f.unpack('U*').pack('U*')  # to get rid of funny encoding related errors
        @all_h[prefix][ff.split(prefix)[1]] = [File.size(ff), File.ctime(ff), File.mtime(ff)]
        puts "(#{ff})" if @options.verbose > 2
        # puts "--#{ff.split(prefix)[1]}"
        puts cnt if cnt % 100 == 0 && @options.verbose > 2
        cnt += 1
      end
    end
  end
  
end

if __FILE__ == $0  
  KSync.new.do_sync  
end