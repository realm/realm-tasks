#!/usr/bin/env ruby
require 'fileutils'
require 'xcodeproj'

# This script does the following:
#
# 1. Comment out Realm pods in Podfile
# 2. Install Cartography
# 3. Embed Realm frameworks for iOS & macOS targets
# 4. Build RealmTasks macOS

fail 'Usage: .packaging/package_release.rb <realm-cocoa-version>' unless ARGV.count == 1
realm_cocoa_version = ARGV[0]

################################################################
# 1. Comment out Realm & RealmSwift pods in Podfile
################################################################

podfile_contents = File.read('RealmTasks Apple/Podfile')
File.open('RealmTasks Apple/Podfile', 'w') do |file|
  file.puts podfile_contents.gsub("    pod 'Realm", "    # pod 'Realm")
end

################################################################
# 2. Install Cartography
################################################################

`pod repo update`
`pod install --project-directory="RealmTasks Apple"`

################################################################
# 3. Embed Realm frameworks for iOS & macOS targets
################################################################

# Get useful variables
@realm_release_root = "../../../SDKs/realm-cocoa_#{realm_cocoa_version}"
@project = Xcodeproj::Project.open('RealmTasks Apple/RealmTasks.xcodeproj')
@frameworks_group = @project.groups.find { |group| group.display_name == 'Frameworks' }

def embed_realm_frameworks(folder, platform_name)
  # Get useful variables
  realm_frameworks_root = "#{@realm_release_root}/#{folder}/swift-2.3"
  target = @project.targets.find { |target| target.to_s == "RealmTasks #{platform_name}" }
  frameworks_build_phase = target.build_phases.find { |build_phase| build_phase.to_s == 'FrameworksBuildPhase' }

  # Remove CocoaPods Manifest check since we're removing the Podfile
  target.build_phases.reject! { |build_phase| build_phase.to_s == '[CP] Check Pods Manifest.lock' }

  # Add new "Embed Frameworks" build phase to target
  embed_frameworks_build_phase = @project.new(Xcodeproj::Project::Object::PBXCopyFilesBuildPhase)
  embed_frameworks_build_phase.name = 'Embed Frameworks'
  embed_frameworks_build_phase.symbol_dst_subfolder_spec = :frameworks
  target.build_phases << embed_frameworks_build_phase

  # Add framework search path to target
  ['Debug', 'Release'].each do |config|
    paths = ['$(inherited)', realm_frameworks_root]
    target.build_settings(config)['FRAMEWORK_SEARCH_PATHS'] = paths
  end

  # Add Realm & RealmSwift frameworks to target as "Embedded Frameworks"
  ['Realm', 'RealmSwift'].each do |framework_name|
    framework_ref = @frameworks_group.new_file("#{realm_frameworks_root}/#{framework_name}.framework")
    build_file = embed_frameworks_build_phase.add_file_reference(framework_ref)
    frameworks_build_phase.add_file_reference(framework_ref)
    build_file.settings = { 'ATTRIBUTES' => ['CodeSignOnCopy', 'RemoveHeadersOnCopy'] }
  end
end

embed_realm_frameworks('ios', 'iOS')
embed_realm_frameworks('osx', 'macOS')

# Save Xcode project
@project.save

################################################################
# 4. Build RealmTasks macOS
################################################################

`xcodebuild -workspace 'RealmTasks Apple/RealmTasks.xcworkspace' -scheme 'RealmTasks macOS' -derivedDataPath 'build' DEVELOPMENT_TEAM='QX5CR2FTN2' CODE_SIGN_IDENTITY='Developer ID Application' PROVISIONING_PROFILE_SPECIFIER='' clean build`
`mv 'build/Build/Products/Debug/RealmTasks.app' .`
