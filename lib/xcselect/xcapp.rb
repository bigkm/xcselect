
module Xcselect
  require 'pathname'
  require 'json'

  class XcApp
    include Comparable
    attr_reader :path
    attr_reader :plist

    def initialize(path)
      @path = path
      @plist = JSON.parse read_plist(plist_path)
    end

    def to_s
      "App: #{sim_version} #{name} : #{bundle_id}"
    end

    def <=>(o)
      result = sim_version.to_f <=> o.sim_version.to_f 
      (!result.zero?) ? result : name <=> o.name
    end
  
    def sim_version
      path.split('/')[-4]
    end

    def [](k)
      @plist[k]
    end

    def base_dir
      File.dirname path
    end

    def bundle_id
      self['CFBundleIdentifier']
    end

    def name
      self['CFBundleName']
    end

    def read_plist path
      `plutil -convert json  -o - '#{path}'`
    end

    def plist_path
      Dir[@path + "/*Info.plist"].first
    end

    def documents_path
      "#{base_dir}/Documents"
    end

    def oomph_app?
      File.exists? "#{path}/Oomph.plist"
    end
    
    def newsstand?
      self['UINewsstandApp'] || false
    end

    def newsstand_path
      "#{base_dir}/Library/Caches/Newsstand"
    end

    def newsstand_issue_paths
      #TODO: make this read the newsstand db and return a hash of names/paths
      if oomph_app? 
        Dir["#{newsstand_path}/*-*/*"]         
      else
        Dir["#{newsstand_path}/*-*"]
      end
    end

    def last_build_time
      File.mtime path
    end
    
    def self.app_support_folder
      File.expand_path("~/Library/Application Support/iPhone Simulator/")
    end
    
    def self.all_apps
      Dir["#{app_support_folder}/**/*.app"].map{|a| XcApp.new a }
    end

    def self.all_newsstand_apps
      self.all_apps.select(&:newsstand?)
    end

    def self.last_built_newsstand_app
      all_newsstand_apps.sort_by!{|e| e.last_build_time }.last
    end

    def self.last_built_app
      XcApp.all_apps.sort_by!{|e| e.last_build_time }.last
    end
    
  end


end