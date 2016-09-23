source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    
    # source podspec
    # pod 'RealmSwift', '1.0.2-15'

    # podspec using binaries for core+sync
    pod 'Realm', git: 'git@github.com:realm/realm-cocoa-private.git', branch: 'sync', submodules: true
    pod 'RealmSwift', git: 'git@github.com:realm/realm-cocoa-private.git', branch: 'sync', submodules: true
    
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
      config.build_settings['SWIFT_VERSION'] = '2.3'
    end
  end
end
