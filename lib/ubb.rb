require "ubb/version"


module Ubb
  def self.sh(cmd)
    print "exec: #{cmd}\n"
    system cmd
    if $? != 0
      raise "ERROR: #{$?.to_i}"
    end
  end
  def self.editor_path
    "#{$project_path}/Assets/Editor"
  end
  def self.has_editor?
    Dir.exist?(self.editor_path)
  end
end

command :showlog do |c|
  c.syntax = 'ubb showlog'
  c.summary = 'show Unity Editor log'
  c.action do |args, options|
    log = '~/Library/Logs/Unity/Editor.log'
    Ubb.sh "less #{log}"
  end
end
alias_command :log, :showlog

command :export do |c|
  c.syntax = 'ubb export [options]'
  c.summary = 'export .unitypackage'
  c.description = 'hoge'
  c.example 'export some folders to unitypackage', 'ubb export --project path/to/unityproject --output some.unitypackage Plugins/Something Resources/Something'
  c.option '--output FILENAME', String, 'specify .unitypackage name'
  c.action do |args, options|
    raise 'specify output filename' if options.output.nil?
    output = (options.output !~ /\.unitypackage$/)? options.output + ".unitypackage" : options.output
    output = File.expand_path(output)
    paths = args.map { |pt| "Assets/#{pt}" }.join(' ')
    Ubb.sh "#{$unity_app_path} -batchmode -projectPath #{$project_path} -exportPackage #{paths} #{output} -quit"
  end
end

command :import do |c|
  c.syntax = 'ubb import [package]'
  c.summary = 'import .unitypackage'
  c.description = 'hoge'
  c.example 'import some unitypackage', 'ubb import --project path/to/unityproject some.unitypackage'
  c.action do |args, options|
    raise 'specify unitypackage file' if args.size == 0
    raise 'too many unitypackage files' if args.size > 1
    input = args[0]
    raise "#{input} does not exist" unless File.exist?(input)
    Ubb.sh "#{$unity_app_path} -batchmode -projectPath #{$project_path} -importPackage #{input} -quit"
  end
end

command :build do |c|
  c.option '--output PATH', String, 'specify output path'
  c.action do |args, options|
    raise 'specify output path' if options.output.nil?
    begin
      output = File.expand_path(options.output)
      has = Ubb.has_editor?
      editor_path = Ubb.editor_path
      FileUtils.mkdir_p editor_path unless has
      src = "#{LIB_PATH}/assets/UbbBuild.cs"
      dst = "#{editor_path}/UbbBuild.cs"
      raise 'build script has already existed' if File.exist?(dst)
      cs = File.read(src)
      csfile = File.open(dst, "w+")
      csfile.write(ERB.new(cs).result binding)
      csfile.flush
      Ubb.sh "#{$unity_app_path} -batchmode -projectPath #{$project_path} -quit -executeMethod Build.PerformiOSBuild -target DEV"
    ensure
      FileUtils.rm_f "#{editor_path}/UbbBuild.cs"
      FileUtils.rm_f "#{editor_path}/UbbBuild.cs.meta"
      unless has
        FileUtils.rm_rf editor_path
        FileUtils.rm_f "#{editor_path}.meta"
      end
    end
  end
end
