module Jewel

    def gnuplot(&block)
      if block
        Jewel.default.instance_eval(&block)
      else
        Jewel.default
      end
    end

    module_function :gnuplot

    def noteplot(&block)
      Jewel::NotePlot.new(&block)
    end
    module_function :noteplot

    class GnuplotError < StandardError; end

  class Gnuplot

    VERSION = "0.1.0"
    POOL = [] of GenNum
    DATA_FORMAT = "%.7g"

    def self.default
      POOL[0] ||= self.new
    end

    class Noteplot

      def initialize(&block)
        if block.nil?
          raise ArgumentError, "Block is needed"
        end
        @block = block
      end

      @@pool = nil

      def to_cr
        require "tempfile"
        tempfile_svg = Tempfile.open(['plot', '.svg'])
        # Output SVG to tmpfile
        @@pool ||= Gnuplot.new(persist:false)
        gp = @@pool
        gp.reset
        gp.set(terminal: 'svg')
        gp.set(output:tempfile_svg.path)
        gp.instance_eval(&@block)
        gp.unset('output')
        svg = File.read(tempfile_svg.path)
        tempfile_svg.close
        return ["image/svg+xml", svg]
      end
    end

    def initialize(path:"gnuplot", persist:true)
      @path = path
      @persist = persist
      @history = [] of GenNum
      @debug = false
      r0, @iow = IO.pipe
      @ior, w2 = IO.pipe
      path += " -persist" if persist
      IO.popen(path, :ing => r0, :err => w2)
      r0.close
      w2.close
      @gnuplot_version = send_cmd("print GPVAL_VERSION")[0].chomp
      if /\.(\w+)$/ =~ (filename = ENV['JEWEL_GNUPLOT_OUTPUT'])
        ext = $1
        ext = KNOWN_EXT[ext] || ext
        opts = ENV['JEWEL_GNUPLOT_OPTION'] || ''
        set terminal:[ext, opts]
        set output:filename
      end
    end

     
