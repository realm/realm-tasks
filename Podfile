source 'git@github.com:realm/cocoapods-specs-private.git'
source 'https://github.com/CocoaPods/Specs.git'

abstract_target 'RealmTasks' do
    use_frameworks!
    
    # source podspec
    # pod 'RealmSwift', '1.0.2-15'

    # binary podspec
    pod 'RealmSwift', '1.0.2-15-sync-1.0.0-beta-31.0'

    pod 'Cartography', git: 'https://github.com/robb/Cartography.git', branch: 'master'
    
    target 'RealmTasks iOS' do
        platform :ios, '9.0'
    end
    
	target 'RealmTasks iOS (CloudKit)' do
		platform :ios, '9.0'
	end

    target 'RealmTasks macOS' do
        platform :osx, '10.10'
    end
    
    target 'RealmTasks iOS Tests' do
        platform :ios, '9.0'
    end
end
