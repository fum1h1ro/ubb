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
  def self.find_project
    return unless $project_path.nil?
    dirs = Dir.glob("**/Assets")
    dirs.each do |d|
      d = d.sub(/(\/)?Assets$/, '')
      if Dir.exist?("#{d}/ProjectSettings")
        $project_path = File.expand_path(d)
      end
    end
  end
  def self.check_target(target)
    cand = [ 'ios', 'android' ]
    cand.select! { |c| c =~ /^#{target}/i }
    return cand[0] if cand.size == 1
    return nil
  end
  def self.check_config(config)
    cand = [ 'development', 'release', 'distribution' ]
    cand.select! { |c| c =~ /^#{config}/i }
    return cand[0] if cand.size == 1
    return nil
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
  Ubb.find_project
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
  Ubb.find_project
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
  Ubb.find_project
  c.syntax = 'ubb build [options]'
  c.summary = 'build project'
  c.description = 'hoge'
  c.example 'build project', 'ubb build --project path/to/unityproject --output path/to/outputproject'
  c.option '--output PATH', String, 'specify output path'
  c.option '--target TARGET', String, 'specify build target (ios|android)'
  c.option '--config COFIGURATION', String, 'specify build configuration (development|release|distribution)'
  c.action do |args, options|
    options.default :config => 'development'
    raise 'specify output path' if options.output.nil?
    raise 'specify target' if options.target.nil?
    output = File.expand_path(options.output)
    target = Ubb.check_target(options.target)
    config = Ubb.check_config(options.config)
    raise "could not recognize a target: \"#{options.target}\"" if target.nil?
    begin
      has = Ubb.has_editor?
      editor_path = Ubb.editor_path
      src = "#{LIB_PATH}/assets/UbbBuild.cs"
      dst = "#{editor_path}/UbbBuild.cs"
      FileUtils.mkdir_p editor_path unless has
      noop = false
      if File.exist?(dst)
        noop = true
        raise 'build script has already existed'
      end
      cs = File.read(src)
      csfile = File.open(dst, "w+")
      csfile.write(ERB.new(cs).result binding)
      csfile.flush
      Ubb.sh "#{$unity_app_path} -batchmode -projectPath #{$project_path} -quit -executeMethod Build.PerformBuild_#{target} -config #{config}"
    ensure
      unless noop
        FileUtils.rm_f "#{editor_path}/UbbBuild.cs"
        FileUtils.rm_f "#{editor_path}/UbbBuild.cs.meta"
        unless has
          FileUtils.rm_rf editor_path
          FileUtils.rm_f "#{editor_path}.meta"
        end
      end
    end
  end
end
