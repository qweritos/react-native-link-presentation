require "json"

package = JSON.parse(File.read(File.join(__dir__, "package.json")))
repository_url = package["repository"]["url"].sub(/^git\+/, "")

Pod::Spec.new do |s|
  s.name         = "react-native-link-presentation"
  s.version      = package["version"]
  s.summary      = package["description"]
  s.homepage     = package["homepage"]
  s.license      = package["license"]
  s.author       = { package["author"]["name"] => package["author"]["email"] }
  s.platforms    = { :ios => "15.1" }
  s.source       = { :git => repository_url, :tag => "v#{s.version}" }
  s.source_files = "ios/**/*.{h,m,mm,swift}"
  s.exclude_files = "ios/RNLinkPresentationTests/**/*"
  s.frameworks   = "LinkPresentation", "UniformTypeIdentifiers"
  s.swift_versions = ["5.9"]

  if respond_to?(:install_modules_dependencies, true)
    install_modules_dependencies(s)
  else
    s.dependency "React-Core"
  end

  s.test_spec "Tests" do |test_spec|
    test_spec.source_files = "ios/RNLinkPresentationTests/**/*.{h,m,mm}"
    test_spec.frameworks = "XCTest"
  end
end
