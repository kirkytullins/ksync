gem 'minitest', '~> 4.4' # use the gem version, not the 1.9 bundled version of minitest
require 'minitest/autorun'

require 'ksync'
require 'fileutils'

require 'turn'

Turn.config.format = :outline

class KSyncTest < MiniTest::Unit::TestCase
    include KSync
    def setup
    begin
      @src_path = File.join(File.dirname(__FILE__), "src/folder1/folder2")
      @dst_path = File.join(File.dirname(__FILE__), "src")
      create_tree("src")
      @opts = {}
      @opts = {:src => File.join(File.dirname(__FILE__), "src"), :dst => File.join(File.dirname(__FILE__), "dst")}
    rescue
      puts "error trying to do the setup :#{$!}"
    end
    end

  def teardown
   FileUtils.rm_rf  @opts[:src]
   FileUtils.rm_rf  @opts[:dst]
  end

  # support methods
  def create_tree(base_path)
    l1 = File.join(File.dirname(__FILE__), base_path)
    l2 = File.join(File.dirname(__FILE__), "#{base_path}/folder1")
    l3 = File.join(File.dirname(__FILE__), "#{base_path}/folder1/folder2")
    l4 = File.join(File.dirname(__FILE__), "#{base_path}/folder_empty")
    FileUtils.mkdir_p File.join(File.dirname(__FILE__),File.join(base_path, "/folder1/folder2"))
    # create some files and write some content
    [l1,l2,l3].each do |folder|
      (1..10).each do |f|
        create_fill_file(File.join(folder, "File%02d" % f))
      end
    end
  end

  def create_fill_file(filename)
    File.open(filename, "w") do |fh|
      (1..10).each do
        fh.write ('a'..'z').to_a.shuffle[0,8].join + "\n"
      end
    end
  end
  # only compares folders based on file existence not file size or other
  def compare_folders(src,dst)
    Find.find(src).each do |f|
      dst_file_folder = f.gsub(src,dst)
      #puts "=> #{dst_file_folder}"
      if !File.exists?(dst_file_folder)
        puts "non existent file #{File.join(dst,f.split('/')[1..-1])}"
        return false
      end
    end
    return true
  end

  # tests
  def test_new_tree
    assert_equal(File.exists?(@opts[:dst]), false, "initial conditions not correct")
    KSync::Base.new(@opts).do_sync
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_nothing_changed
    create_tree("dst")
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
    assert_equal(KSync::Base.new(@opts).do_sync, false)
  end

  def test_more_files_in_source
    create_fill_file(File.join(@opts[:src],"NEWFILE.txt"))
    assert_equal(KSync::Base.new(@opts).do_sync, true)
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_more_folders_in_source
    FileUtils.mkdir_p (File.join(@opts[:src],"NEW_FOLDER/NEW_FOLDER"))
    assert_equal(KSync::Base.new(@opts).do_sync, true)
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_less_files_in_source
    FileUtils.rm(File.join(@opts[:src],"File01"))
    assert_equal(KSync::Base.new(@opts).do_sync, true)
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_less_folders_in_source
    FileUtils.rm_rf "#{@opts[:src]}/folder_empty"
    assert_equal(KSync::Base.new(@opts).do_sync, true)
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_source_file_changed_using_hash
    create_fill_file(File.join(@opts[:src],"File01"))
    @opts[:use_hash] = true
    assert_equal(KSync::Base.new(@opts).do_sync, true)
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
  end

  def test_dont_create_src_folder
    @opts2 = {:src => File.join(File.dirname(__FILE__), "src_non"), :dst => File.join(File.dirname(__FILE__), "dst_non")}
    assert_equal(File.exists?(@opts2[:src]), false, "initial conditions not correct")
    @opts2[:verbose] = 3
    assert_equal(KSync::Base.new(@opts2).do_sync, false)
  end

  def test_dry_run
    assert_equal(File.exists?(@opts[:dst]), false, "initial conditions not correct")
    @opts[:real_copy] = false
    @opts[:verbose] = 3
    @opts[:force_dest_hash] = true
    KSync::Base.new(@opts).do_sync
    assert_equal(File.exists?(@opts[:dst]), false)
  end

  def test_use_existing_files_hash
    assert_equal(File.exists?(@opts[:dst]), false, "initial conditions not correct")
    k = KSync::Base.new(@opts)
    k.do_sync
    assert_equal(compare_folders(@opts[:src], @opts[:dst]), true)
    saved_hash = File.open(File.join(@opts[:dst], KSync::Base::KSYNC_FILES_HASH),'r').read
    teardown
    setup
    File.open(File.join(@opts[:dst], KSync::Base::KSYNC_FILES_HASH),'w'){|f| f.write saved_hash}
    assert_equal(KSync::Base.new(@opts).do_sync, false)
    FileUtils.rm File.join(@opts[:dst], KSync::Base::KSYNC_FILES_HASH) rescue nil
  end

end