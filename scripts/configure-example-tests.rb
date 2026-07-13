require "xcodeproj"

project_path = File.expand_path("../example/ios/LinkPresentationExample.xcodeproj", __dir__)
project = Xcodeproj::Project.open(project_path)
app = project.targets.find { |target| target.name == "LinkPresentationExample" }
abort "Example app target not found" unless app

test = project.targets.find { |target| target.name == "RNLinkPresentationTests" }
unless test
  test = project.new_target(:unit_test_bundle, "RNLinkPresentationTests", :ios, "15.1")
  test.add_dependency(app)
end

group = project.main_group.find_subpath("RNLinkPresentationTests", true)
%w[
  RNLinkPresentationRegistryTests.mm
  RNLPLinkViewTests.mm
  RNMetadataProviderTests.mm
].each do |name|
  reference = group.files.find { |file| file.path&.end_with?(name) }
  unless reference
    reference = group.new_file("../../ios/RNLinkPresentationTests/#{name}")
  end
  unless test.source_build_phase.files_references.include?(reference)
    test.source_build_phase.add_file_reference(reference)
  end
end

test.build_configurations.each do |configuration|
  settings = configuration.build_settings
  settings["BUNDLE_LOADER"] = "$(TEST_HOST)"
  settings["CODE_SIGNING_ALLOWED"] = "NO"
  settings["GENERATE_INFOPLIST_FILE"] = "YES"
  settings["PRODUCT_BUNDLE_IDENTIFIER"] = "org.reactjs.native.example.RNLinkPresentationTests"
  settings["PRODUCT_NAME"] = "$(TARGET_NAME)"
  settings["TEST_HOST"] = "$(BUILT_PRODUCTS_DIR)/LinkPresentationExample.app/$(BUNDLE_EXECUTABLE_FOLDER_PATH)/LinkPresentationExample"
end

project.save
