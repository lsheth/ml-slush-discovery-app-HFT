require 'lib/RoxyHttp'
#
# Put your custom functions in this class in order to keep the files under lib untainted
#
# This class has access to all of the private variables in deploy/lib/server_config.rb
#
# any public method you create here can be called from the command line. See
# the examples below for more information.
#
class ServerConfig
  def role
    @properties['ml.app-name'] + "-role"
  end

  #
  # You can easily "override" existing methods with your own implementations.
  # In ruby this is called monkey patching
  #
  # first you would rename the original method
  alias_method :original_deploy_modules, :deploy_modules

  # then you would define your new method
  def deploy_modules
    password_prompt
    system %Q!mlpm install!
    system %Q!mlpm deploy -u #{ @properties['ml.user'] } \
                      -p #{ @ml_password } \
                      -H #{ @properties['ml.server'] } \
                      -P #{ @properties['ml.app-port'] }!
    original_deploy_modules
  end

  alias_method :original_deploy_rest, :deploy_rest

  def deploy_rest
    optionFiles = Dir[ServerConfig.expand_path("../../../rest-api/config/options/all/*")]
    headers = {
      'Content-Type' => 'application/xml'
    }
    optionFiles.each { |filePath|
      file = open(filePath, "rb")
      contents = file.read
      searchOptionPart = File.basename(filePath, ".*")
      url = "http://#{@properties['ml.server']}:#{@properties['ml.app-port']}/v1/config/query/all/#{searchOptionPart}"
      puts url
      r = go(url, "PUT", headers, nil, contents)
      if (r.code.to_i < 200 && r.code.to_i > 206)
        @logger.error("code: #{r.code.to_i} body:#{r.body}")
      end
    }

    deploy_ext()
    deploy_transform()
  end
  #
  # you can define your own methods and call them from the command line
  # just like other roxy commands
  # ml local my_custom_method
  #
  # def my_custom_method()
  #   # since we are monkey patching we have access to the private methods
  #   # in ServerConfig
  #   @logger.info(@properties["ml.content-db"])
  # end

  #
  # to create a method that doesn't require an environment (local, prod, etc)
  # you woudl define a class method
  # ml my_static_method
  #
  # def self.my_static_method()
  #   # This method is static and thus cannot access private variables
  #   # but it can be called without an environment
  # end
def deploy_rawdata

  
       arguments_rawdata = %W{
       import -mode local
      -input_file_path data/AAPL_1M_CSV.csv
      -input_file_type delimited_text
      -delimited_uri_id Key
      -delimited_root_name Raw_data
      -output_uri_prefix /Raw_data/
      -output_collections Raw_data
      -transform_module /transform/Rawdata-transform.xqy
      -transform_namespace http://marklogic.com/transform/rawdata      
      -transform_function transform
      -output_permissions
      #{role},read,#{role},update,#{role},insert,#{role},execute
      }
      mlcp(arguments_rawdata)
end

def mlcp(arguments)
    mlcp_home = @properties['ml.mlcp-home']
    if @properties['ml.mlcp-home'] == nil || ! File.directory?(File.expand_path(mlcp_home)) || ! File.exists?(File.expand_path("#{mlcp_home}/bin/mlcp.sh"))
      raise "MLCP not found or mis-configured, please check the mlcp-home setting."
    end

    # Find all jars required for running MLCP. At least:
    jars = Dir.glob(ServerConfig.expand_path("#{mlcp_home}/lib/*.jar"))
    classpath = jars.join(path_separator)

    arguments.each_with_index do |arg, index|
      if arg == "-option_file"
        # remove flag from arguments
        arguments.slice!(index)

        # capture and remove value from arguments
        option_file = arguments[index]
        arguments.slice!(index)

        # find and read file if exists
        option_file = ServerConfig.expand_path("#{@@path}/#{option_file}")
        if File.exist? option_file
          logger.debug "Reading options file #{option_file}.."
          options = File.read option_file

          # substitute properties
          @properties.sort {|x,y| y <=> x}.each do |k, v|
            options.gsub!("@#{k}", v)
          end

          logger.debug "Options after resolving properties:"
          lines = options.split(/[\n\r]+/).reject { |line| line.empty? || line.match("^#") }

          lines.each do |line|
            logger.debug line
          end

          # and insert the properties back into arguments
          arguments[index,0] = lines
        else
          raise "Option file #{option_file} not found."
        end
      end
    end

    @ml_username = @properties['ml.mlcp-user'] || @properties['ml.user']
    @ml_password = @properties['ml.mlcp-password'] || @ml_password
    if arguments.length > 0
      password_prompt
      connection_string = %Q{ -username #{@ml_username} -password #{@ml_password} -host #{@properties['ml.server']} -port #{@properties['ml.xcc-port']}}

      runme = %Q{java -cp "#{classpath}" #{@properties['ml.mlcp-vmargs']} com.marklogic.contentpump.ContentPump #{arguments.join(' ')} #{connection_string}}
    else
      runme = %Q{java -cp "#{classpath}" com.marklogic.contentpump.ContentPump}
    end

    logger.info runme
    logger.info ""
    system runme
    logger.info ""
end  

end

#
# Uncomment, and adjust below code to get help about your app_specific
# commands included into Roxy help. (ml -h)
#

#class Help
#  def self.app_specific
#    <<-DOC.strip_heredoc
#
#      App-specific commands:
#        example       Installs app-specific alerting
#    DOC
#  end
#
#  def self.example
#    <<-DOC.strip_heredoc
#      Usage: ml {env} example [args] [options]
#
#      Runs a special example task against given environment.
#
#      Arguments:
#        this    Do this
#        that    Do that
#
#      Options:
#        --whatever=value
#    DOC
#  end
#end
