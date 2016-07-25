source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    
    pod 'RealmSwift', '1.0.2-2-sync-0.25.1'
    
    target 'RealmTasks iOS' do
        platform :ios, '9.0'
        
        pod 'Cartography'
    end
    
    target 'RealmTasks macOS' do
        platform :osx, '10.10'
    end
end
