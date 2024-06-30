platform :ios, '17.5'

target 'BlurrrDatingApp' do
  use_frameworks!

  # Pods for BlurrrDatingApp
  pod 'JitsiMeetSDK'#, '9.2.2' # Specify the version you want to use
  #pod 'Socket.IO-Client-Swift'
  #pod 'Starscream'
  pod 'NSFWDetector'
  pod 'GoogleSignIn'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.5'
    end
  end

  # Resolve conflicts between JitsiMeetSDK and GoogleSignIn by excluding duplicate symbols
  installer.pods_project.targets.each do |target|
    if target.name == 'Pods-BlurrrDatingApp'
      target.build_configurations.each do |config|
        config.build_settings['OTHER_LDFLAGS'] = '-ObjC -l"GoogleSignIn" -l"JitsiMeetSDK" -force_load $(BUILT_PRODUCTS_DIR)/GoogleSignIn/GoogleSignIn.framework/GoogleSignIn -force_load $(BUILT_PRODUCTS_DIR)/JitsiMeetSDK/JitsiMeetSDK.framework/JitsiMeetSDK'
      end
    end
  end
end

