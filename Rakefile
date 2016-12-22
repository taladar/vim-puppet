#!/usr/bin/env rake

task :ci => [:dump, :test]

task :dump do
  sh 'vim --version'
end

task :test do
  sh 'bundle exec vim-flavor test'
end

task :interactive do
  sh 'vim -u test_vimrc test_vimrc'
end
