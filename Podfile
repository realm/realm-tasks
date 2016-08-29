source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    
    pod 'RealmSwift', '1.0.2-10-sync-1.0.0-beta-29.0'
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
