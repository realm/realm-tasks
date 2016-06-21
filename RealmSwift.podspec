Pod::Spec.new do |s|
  s.name                      = 'RealmSwift'
  cocoa_version               = '1.0.0-3'
  s.version                   = "#{cocoa_version}-sync-0.23.2"
  release_name                = "realm-swift_#{s.version}"
  s.summary                   = 'Realm is a modern data framework & database for iOS & OS X.'
  s.description               = <<-DESC
                                The Realm database, for Swift. (If you want to use Realm from Objective-C, see the “Realm” pod.)

                                Realm is a mobile database: a replacement for Core Data & SQLite. You can use it on iOS & OS X. Realm is not an ORM on top SQLite: instead it uses its own persistence engine, built for simplicity (& speed). Learn more and get help at https://realm.io
                                DESC
  s.homepage                  = "https://realm.io"
  s.source                    = { :http => "https://static.realm.io/downloads/sync/9672cdf129740d4489a161bea4b3eb231edd46aa/#{release_name}.zip" }
  s.author                    = { 'Realm' => 'help@realm.io' }
  s.requires_arc              = true
  s.social_media_url          = 'https://twitter.com/realm'
  s.documentation_url         = "https://realm.io/docs/swift/latest"
  s.license                   = 'Apache 2.0'


  s.ios.deployment_target   = '8.0'
  s.ios.vendored_frameworks = "ios/swift-2.2/RealmSwift.framework", "ios/swift-2.2/Realm.framework"

  s.osx.deployment_target   = '10.9'
  s.osx.vendored_frameworks = "osx/swift-2.2/RealmSwift.framework", "osx/swift-2.2/Realm.framework"
end