# Uncomment the next line to define a global platform for your project
 platform :ios, '11.0'

target 'OneSignalNotificationServiceExtension' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
   pod 'OneSignal', '>= 2.11.2', '< 3.0'
   pod 'Firebase/Database'
   pod 'Firebase/Auth'
   pod 'GoogleSignIn'
   pod 'FBSDKLoginKit'
   pod 'SwiftyStoreKit'
   pod 'SDWebImage', '~> 5.0'
   
   post_install do |installer|
     installer.pods_project.targets.each do |target|
       target.build_configurations.each do |config|
         config.build_settings['APPLICATION_EXTENSION_API_ONLY'] = 'No'
       end
     end
   end

   
end

target 'WebView' do
  # Comment the next line if you don't want to use dynamic frameworks
  use_frameworks!
   pod 'OneSignal', '>= 2.11.2', '< 3.0'
  # Pods for WebView

end
