require 'fileutils'
require 'digest'
require 'find'
require 'yaml'

# this is the main KSync module
module KSync
  # this is the only class in the KSync module, needs to be instantiated
  class Base

    # index for size of file
    SSIZE_I=0
    # index for modification date of file
    MTIME_I=1

    # the name of the file containing the hash for the destination folder
    KSYNC_FILES_HASH = '.ksync_files_hash'

    # the version of the ksync gem
    VERSION = '0.5.1'

    attr_accessor :all_h, :ll
    # initializes the class
    def initialize(init_opt)
      @all_h={}
      @changes = false
      init_opt[:real_copy] = init_opt[:real_copy] == nil ? true : init_opt[:real_copy]
      init_opt[:use_hash] = init_opt[:use_hash] == nil ? false : init_opt[:use_hash]
      init_opt[:verbose] = init_opt[:verbose] == nil ? 0 : init_opt[:verbose]
      init_opt[:force_dest_hash] = init_opt[:force_dest_hash] == nil ? false : init_opt[:force_dest_hash]

      return nil if !init_opt[:src] | !init_opt[:dst]
      @options = init_opt
      @ll = [init_opt[:src], init_opt[:dst]]
      create_hash
    end

    # this method does the actual syncing : frontend
    def do_sync
      # browse source hash to detect new and changed files
      return false unless File.exists?(ll.first)
      all_h[ll.first].each do |k,v|
        src_fp = File.join(ll.first,k)
        dst_fp = File.join(ll.last,k)
        if !all_h[ll.last][k]
          copy_del_actions('New', k, src_fp, dst_fp)
        else
          if !File.directory?(File.join(ll.first,k))
            copy_del_actions('Changed',k, src_fp, dst_fp) if !same?(src_fp, dst_fp, v, all_h[ll.last][k])
          end
        end
      end
      # browse destination hash to detect obsolete files
      all_h[ll.last].each do |k,v|
        #next if File.join(ll.last,KSYNC_FILES_HASH) == f  # ignore files list hash

        if !all_h[ll.first][k]
          dst_fp = File.join(ll.last,k)
          copy_del_actions('Deleted', k, nil, dst_fp )
        end
      end
      #puts "there were changes" if @changes
      #puts "nothing changed" if !@changes
      save_files_hash(File.join(ll.last, KSYNC_FILES_HASH)) if @changes and @options[:real_copy] == true
      return @changes
    end

    # saves the files hash to disk
    def save_files_hash(file)
      File.open(file, 'w'){|f| f.write all_h[ll.last].to_yaml }
    end

    #loads the files hash from disk
    def load_files_hash(file)
      return YAML::load_file(file)
    end

    # calculate a hash of a file
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

    # does the actual copy between source and destination
    def do_copy(src_fp, dst_fp)
      begin
        if File.directory?(src_fp)
          file_op = "mkdir"
          FileUtils.mkdir_p dst_fp
        else
          file_op = "cp"
          FileUtils.copy_file src_fp, dst_fp
        end
      rescue
        puts "ERR: while copying (#{file_op}) [#{src_fp} to #{dst_fp}] : (#{$!})"
      end
    end

    # deletes file from destination
    def do_delete (dst_fp)
      begin
        if File.exists?(dst_fp)
          if File.directory?(dst_fp)
            file_op = 'remove_dir'
            FileUtils.remove_dir(dst_fp)
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
        if dst[MTIME_I] - dst[MTIME_I]  >=  0
          date_ok = true
        else
          puts "DATE diff for #{src_fp} vs #{dst_fp}" if @options[:verbose] > 1
        end
      else
        puts "SIZE diff for #{src_fp} vs #{dst_fp}" if @options[:verbose] > 1
      end
      return false if !size_ok
      return false if !date_ok
      return true if !@options[:use_hash]
      h1 = get_hash(src_fp)
      h2 = get_hash(dst_fp)
      if h1 != h2
        puts "SHA1 diff for #{src_fp} vs #{dst_fp}" if @options[:verbose] > 1
        return false
      end
      return true
    end

    #creates the initial file list hash for the source and potentially the destination
    def create_hash
      if !File.exists?(ll.first)
        puts "source folder #{ll.first} does not exist ! "
        return
      end
      ll.each do |prefix|
        all_h[prefix] = {}
        if prefix == ll.last
          next if @options[:real_copy] == false
          dest_hash_file_name = File.join(ll.last,KSYNC_FILES_HASH)
          if File.exists?(dest_hash_file_name) && @options[:force_dest_hash] == false
            all_h[prefix] = load_files_hash(dest_hash_file_name)
            next unless @options[:force_dest_hash]
          end
        end

        cnt = 0
        if !File.exists?(prefix)
          puts "creating folder #{prefix}" if @options[:verbose] > 1
          FileUtils.mkdir_p prefix
        end

        Find.find(prefix).each do |f|
          next if prefix == f
          ff = f.unpack('U*').pack('U*')  # to get rid of funny encoding related errors
          all_h[prefix][ff.split(prefix)[1]] = [File.size(ff), File.mtime(ff)]
          puts "(#{ff})" if @options[:verbose] > 2
          puts cnt if cnt % 100 == 0 && @options[:verbose] > 1
          cnt += 1
        end

        save_files_hash(File.join(ll.last, KSYNC_FILES_HASH)) if prefix == ll.last

      end
    end

    private

    def copy_del_actions(action, k, src_fp, dst_fp)
      puts "#{action}: #{k}" if @options[:verbose] > 0
      if action == 'Deleted'
        if @options[:real_copy]
          do_delete dst_fp
          all_h[ll.last].delete(k)
        end
      else
        if @options[:real_copy]
          do_copy(src_fp, dst_fp) if @options[:real_copy]
          all_h[ll.last][k] = [File.size(dst_fp), File.mtime(dst_fp)]
        end
      end
      @changes = true unless @changes
    end


  end
end