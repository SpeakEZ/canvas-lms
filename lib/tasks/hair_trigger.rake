$VERBOSE = nil
Dir["#{Gem::Specification.find_by_name('hairtrigger').gem_dir}/lib/tasks/*.rake"].each { |ext| load ext }
