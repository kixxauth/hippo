ROOT = File.dirname __FILE__

task :default => :build

directory 'tmp'
directory 'dist'
directory 'dist/lib'
directory 'dist/bin'

desc "Build Hippo"
build_deps = [
    :setup,
    'dist/lib/server.js',
    'dist/package.json',
    'dist/hippo-cli.js',
    'dist/index.js',
    'dist/package.json',
    'dist/bin/hippo.js'
]
task :build => build_deps do
    puts "Built Hippo"
end

desc "Run Treadmill tests for Hippo"
task :test => [:build, :setup] do
    system 'bin/runtests'
end

task :setup => 'tmp/setup.dump' do
    puts "dev environment setup done"
end

desc "Publish Hippo with npm"
task :publish => [:clean, :setup, :build] do
    sh 'bin/runtests' do |ok, id|
        ok or fail "not publishing: test failed"
    end
    Dir.chdir 'dist'
    sh 'npm publish' do |ok, id|
        ok or fail "npm could not publish Hippo"
    end
    Dir.chdir ROOT
end

task :clean do
    rm_rf 'tmp'
    rm_rf 'node_modules'
    rm_rf 'dist'
end

file 'tmp/setup.dump' => ['dev.list', 'tmp'] do |task|
    list = File.open(task.prerequisites.first, 'r')
    list.each do |line|
        npm_install(line)
    end
    File.open(task.name, 'w') do |fd|
        fd << "done"
    end
end

file 'dist/package.json' => ['package.json', 'dist'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
    Dir.chdir 'dist'
    sh 'npm install' do |ok, id|
        ok or fail "npm could not install Hippo dependencies"
    end
    Dir.chdir ROOT
end

file 'dist/bin/hippo.js' => ['bin/hippo.js', 'dist/bin'] do |task|
    FileUtils.cp task.prerequisites.first, task.name
end

file 'dist/hippo-cli.js' => ['hippo-cli.coffee', 'dist'] do |task|
    brew_javascript task.prerequisites.first, task.name, true
end

file 'dist/index.js' => ['index.coffee', 'dist'] do |task|
    brew_javascript task.prerequisites.first, task.name, true
end

file 'dist/lib/server.js' => ['lib/server.coffee', 'dist/lib'] do |task|
    brew_javascript task.prerequisites.first, task.name
end

def npm_install(package)
    sh "npm install #{package}" do |ok, id|
        ok or fail "npm could not install #{package}"
    end
end

def brew_javascript(source, target, node_exec=false)
    File.open(target, 'w') do |fd|
        if node_exec
            fd << "#!/usr/bin/env node\n\n"
        end
        fd << %x[./node_modules/.bin/coffee -pb #{source}]
    end
end
