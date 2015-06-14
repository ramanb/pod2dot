#
# Takes a CocoaPod file and generates a Dot file which can then be loaded into Graphviz
# for a visual graph of dependencies.
#
# Algorithm is:
#   Read all the Pods definitions into a Hash map.i.e. until the next empty line in "Podfile.lock". 
#   This will include loading the list of dependencies for each pod.
#   Then resolve the CocoaPod dependencies with concrete version numbers.
#   Some assumptions are made in resolving the dependencies ...
#   Finally dump a directed graph in dot format on stdout.
#   Then use Graphviz elsewhere to produce a graph.
#
# Notes:
# 1) Tested with CocoaPods 0.33.1 only. Changes may be required for later versions of CocoaPods.
# 2) Did not exploit the dependencies section in "Podfile.lock" as it seems somewhat consistent in
#    how it represents dependencies.i.e. not all dependencies are included in this section. 
# 3) Error handling could be improved.
# 4) Only tested with 200 odd nodes. The simple coloring scheme used may not extend for larger number of nodes.
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

def check(lines,pods) 
    entries=0
    pods.each do |k,v|
       entries=entries+1
       v.deps.each do |d|
          entries=entries+1
       end
    end
    begin
        raise "ParsingError" unless entries==lines
        rescue
            puts "Parsing error: Number of lines in PODS section <> No entries in internal hashmap"
            exit
    end
end

def parsePodFile(filename)
    podhash = Hash.new
    lineno = 0
    File.open(filename,"r") do |infile| 
       while (line = infile.gets)
            if line =~ /^PODS:$/
                next
            elsif line =~ /^$/
                break
            end

            lineno=lineno + 1
            m = line.match(/(.*-\s)([a-zA-Z0-9\-\/]+)(\s\()?([~> 0-9.]+)?/)
            if line =~ /^\s\s-/
                    pod = Pod.new(m[2],m[4])
                    podhash[pod.name] = pod
            elsif line =~ /^\s\s\s\s-/
                    dep = Pod.new(m[2],m[4])
                    pod.deps.push(dep)
            end
       end
    end

    check(lineno,podhash)
    return podhash
end

# Resolve the version numbers for the pod dependencies.
# The algorithm is replace any CocoaPod  version number with a concrete value. 
# Assumes that multiples versions of a library do not exist in your Podfile.lock file. 
def resolvePodVersions(podhash)
    podhash.each do |k,v|
       v.deps.each do |d|
            d.version = podhash[d.name].version
       end
    end
end

def debug(podhash)
    podhash.each do |k,v|
       puts "#{k},#{v.version},#{v.deps.length}"
       v.deps.each do |d|
            puts "...#{d.name},#{d.version}"
       end
    end
end

#
# Print out the dot file
#
def outputDot(podhash)
    # Random set of 16 colors ...
    colors = [0xFF00FF,0x9900FF,0x99CCFF,0x00CC99,
              0x0000FF,0xFFCC00,0xFF9900,0xFF0000,
              0xCC00CC,0x6666FF,0xFF99FF,0x6699FF,
              0x993399,0xFFCCFF,0x6600FF,0xCC00FF,
              0x00FF00,0xFF0033,0xFF0033,0xCCCCCC];

    puts "digraph PodDeps {"
    puts "\tsize=\"8,6\";"
    puts "\tnode[fontsize=10];"

    count = 0
    podhash.each do |k,v|
       # Only color if there are more than 2 edges from this node.
       if v.deps.length > 2
            colorstring = sprintf("\"\#%06x\"",colors[count%16])
            puts "\tedge [color=#{colorstring}];"
            count = count + 1
       else
            colorstring = sprintf("\"\#000000\"")
            puts "\tedge [color=black];"
       end
       v.deps.each do |d|
            puts "\t\"#{k} #{v.version}\" -> \"#{d.name} #{d.version}\";"
       end
       puts "\t\"#{k} #{v.version}\" [color=#{colorstring}];";
    end
    puts "}"
end

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
    podhash=parsePodFile(options[:filename])
    resolvePodVersions(podhash)
    outputDot(podhash)
end

