source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    
    pod 'RealmCore', git: '../realm-core', branch: 'jp-podspec'
    pod 'RealmSync', git: '../realm-sync', branch: 'jp-podspec'
    pod 'Realm', git: '../realm-cocoa', branch: 'jp-sync-podspec', submodules: true
    pod 'RealmSwift', git: '../realm-cocoa', branch: 'jp-sync-podspec'
    pod 'Cartography'
    
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
