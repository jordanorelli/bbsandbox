guard :rspec, cmd: 'bundle exec rspec' do
  watch('bristlecode.rb') { "spec" }
  watch(%r{^spec/.+(_spec\.rb)$}) { "spec" }
end
