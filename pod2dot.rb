#
# Script that takes a Pod file and generates a Dot file which can then be loaded into Graphviz
# for a visual graph of dependencies.
# Notes:
# 1) Works with CocoaPods 0.33.1
# 2) I did not get the dependencies section in "Podfile.lock" as it seems to not be consistent in 
#    representing all dependencies so ignored here.
#
# Algorithm is:
#   Read all the Pods definitions into a Hash map. 
#   This will include loading the list of dependencies.
#   Then resolve the CocoaPod dependencies in a simple way with concrete version numbers.
#   Finally dump the hash map to dot syntax on stdout.
#

require 'optparse'

class Pod
   attr_accessor :name,:version,:deps

   def initialize(name,version)
	@name = name
	@version = version
        self.deps = [] # Initialise the array
   end
end

def parsePodFile(filename)
    podmap = Hash.new
    File.open(filename,"r") do |infile| 
       while (line = infile.gets)
            if line.match("PODS:")
                next
            elsif line =~ /^$/
                break
            end

    #	m = line.match(/(.*) ([a-zA-Z\-\/]+) \(?([0-9.~> ]+)?\)?(:)?/)
            m = line.match(/(.*-\s)([a-zA-Z0-9\-\/]+)(\s\()?([~> 0-9.]+)?/)
    #	puts "#{m[1]} | #{m[2]} |  #{m[3]} | #{m[4]} | #{m[5]}"
            if line =~ /^\s\s-/
                    pod = Pod.new(m[2],m[4])
                    podmap[pod.name] = pod
            elsif line =~ /^\s\s\s\s-/
                    dep = Pod.new(m[2],m[4])
                    pod.deps.push(dep)
            end
       end
    end
    return podmap
end

# Fix up the version numbers for the pod dependencies
# The algorithm is replace any CocoaPod style version number with
# a concrete value. Assumes that multiples versions of a library do not
# exist in your Podfile.lock. I do not believe that this is possible in CocoaPods.
#
def resolvePodVersions(podmap)
    podmap.each do |k,v|
       v.deps.each do |d|
            d.version = podmap[d.name].version
       end
    end
end

def debug(podmap)
    podmap.each do |k,v|
       puts "#{k},#{v.version},#{v.deps.length}"
       v.deps.each do |d|
            puts "...#{d.name},#{d.version}"
       end
    end
end

def outputDot(podmap)
    # Print out the dot file
    puts "digraph PodDeps {"
    puts "\tsize=\"8,6\";"
    puts "\tnode[fontsize=10];"

    podmap.each do |k,v|
       v.deps.each do |d|
            puts "\t\"#{k} #{v.version}\" -> \"#{d.name} #{d.version}\";"
       end
    end
    puts "}"
end

#
# The solution for handling no args is probably a bit lame!
#
def parseOptions() 
    ARGV << '-h' if ARGV.empty?

    options = {}
    options[:filename] = ""

    optparse = OptionParser.new do |opts|
        opts.banner = "Usage: pods2dot.rb [options] podfile" 
        opts.on( '-h', '--help', 'Display this screen' ) do  
            puts opts
            exit
        end
    end

    optparse.parse!
  
    if ARGV.empty? 
        exit
    end

    options[:filename] = ARGV[0]
    return options
end

if __FILE__ == $0
    options = parseOptions()
    podmap=parsePodFile(options[:filename])
#	debug(podmap)
    resolvePodVersions(podmap)
    outputDot(podmap)
end

