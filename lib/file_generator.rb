

module Mkduino
  class GeneratedFile
    attr_accessor :output_filename, :output_directory
    attr_accessor :backup_directory, :user_updates_file

    def initialize output_filename, options = {}
      @output_filename = output_filename
      @output_directory = options[:output_directory] || '.' + File::SEPARATOR
      @backup_directory = options[:backup_directory] || 'generated'
      @user_updates_file = options[:user_updates_file] || @output_filename + ".patch"

      @output_directory = @output_directory + File::SEPARATOR unless @output_directory[-1] == File::SEPARATOR
      @backup_directory = @backup_directory + File::SEPARATOR unless @backup_directory[-1] == File::SEPARATOR
      puts "GeneratedFile.output_filename " + @output_filename
    end

    def write_file
      File.open("#{@output_directory}#{@output_filename}","w") do |f|
        yield f
      end
    end

    def save_file
      unless Dir.exist?(@backup_directory)
        Dir.mkdir(@backup_directory)
      end
      File::cp("#{output_directory}#{@output_filename}",@backup_directory)
    end

    def save_user_updates
      if(Pathname.new("#{output_directory}#{@output_file}").exist? &&
         Pathname.new("#{@backup_directory}#{@output_file}"))
        `diff -u #{@backup_directory}#{output_file} #{@output_directory}#{output_file} > #{user_updates_file}`
      end

    end

    def apply_user_updates
      `patch < #{user_updates_file}`
    end


  end
end
