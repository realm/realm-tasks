source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    

    # build from source
    pod 'Realm', git: 'https://github.com/realm/realm-cocoa-private.git', branch: 'sync'
    pod 'RealmSwift', git: 'https://github.com/realm/realm-cocoa-private.git', branch: 'sync'
    
    # 'master' of Cartography contains Swift 2.3 compatibility
    pod 'Cartography', git: 'https://github.com/robb/Cartography.git', branch: 'master'
    
    target 'RealmTasks iOS' do
        platform :ios, '9.0'
    end
    
    target 'RealmTasks macOS' do
        platform :osx, '10.10'
    end
    
    target 'RealmTasks iOS Tests' do
        platform :ios, '9.0'
    end
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['SWIFT_VERSION'] = '2.3' # or '3.0'
    end
  end
end