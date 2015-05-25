require 'erbse/evaluator'
require 'erbse/context'


module Erbse


  ##
  ## (abstract) abstract engine class.
  ## subclass must include evaluator and converter module.
  ##
  class Engine
    def initialize(input=nil, properties={})
      #@input = input
      init_generator(properties)
      init_converter(properties)
      init_evaluator(properties)
      @src    = convert(input) if input
    end


    ##
    ## convert input string and set it to @src
    ##
    def convert!(input)
      @src = convert(input)
    end


    # FIXME: this caching is redundant as we got that in Tilt AND cells.
    ##
    ## load file, write cache file, and return engine object.
    ## this method create code cache file automatically.
    ## cachefile name can be specified with properties[:cachename],
    ## or filname + 'cache' is used as default.
    ##
    def self.load_file(filename, properties={})
      cachename = properties[:cachename] || (filename + '.cache')
      properties[:filename] = filename
      timestamp = File.mtime(filename)
      if test(?f, cachename) && timestamp == File.mtime(cachename)
        engine = self.new(nil, properties)
        engine.src = File.read(cachename)
      else
        input = File.open(filename, 'rb') {|f| f.read }
        engine = self.new(input, properties)
        tmpname = cachename + rand().to_s[1,8]
        File.open(tmpname, 'wb') {|f| f.write(engine.src) }
        File.rename(tmpname, cachename)
        File.utime(timestamp, timestamp, cachename)
      end
      engine.src.untaint   # ok?
      return engine
    end


    ##
    ## helper method to convert and evaluate input text with context object.
    ## context may be Binding, Hash, or Object.
    ##
    def process(input, context=nil, filename=nil)
      code = convert(input)
      filename ||= '(erubis)'
      if context.is_a?(Binding)
        return eval(code, context, filename)
      else
        context = Context.new(context) if context.is_a?(Hash)
        return context.instance_eval(code, filename)
      end
    end


    ##
    ## helper method evaluate Proc object with contect object.
    ## context may be Binding, Hash, or Object.
    ##
    def process_proc(proc_obj, context=nil, filename=nil)
      if context.is_a?(Binding)
        filename ||= '(erubis)'
        return eval(proc_obj, context, filename)
      else
        context = Context.new(context) if context.is_a?(Hash)
        return context.instance_eval(&proc_obj)
      end
    end


  end  # end of class Engine


  ##
  ## (abstract) base engine class for Eruby, Eperl, Ejava, and so on.
  ## subclass must include generator.
  ##

  module Basic

  end

  class Basic::Engine < Engine
    include Evaluator
    include Basic::Converter
  end

end
