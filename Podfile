platform :ios, '17.5'

target 'BlurrrDatingApp' do
  use_frameworks!
  pod 'NSFWDetector'
  pod 'GoogleSignIn'
  pod 'Starscream'
  pod 'WebRTC-SDK', '~> 114.0'
end

post_install do |installer|
  installer.pods_project.targets.each do |target|
    target.build_configurations.each do |config|
      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.5'
      config.build_settings['CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES'] = 'YES'
    end
  end
end

#post_install do |installer|
#  installer.pods_project.targets.each do |target|
#    target.build_configurations.each do |config|
#      config.build_settings['IPHONEOS_DEPLOYMENT_TARGET'] = '17.5'
#    end
#  end
#end

#  # Resolve conflicts between JitsiMeetSDK and GoogleSignIn by excluding duplicate symbols
#  installer.pods_project.targets.each do |target|
#    if target.name == 'Pods-BlurrrDatingApp'
#      target.build_configurations.each do |config|
#        config.build_settings['OTHER_LDFLAGS'] = '-ObjC -l"GoogleSignIn" -l"JitsiMeetSDK" -force_load $(BUILT_PRODUCTS_DIR)/GoogleSignIn/GoogleSignIn.framework/GoogleSignIn -force_load $(BUILT_PRODUCTS_DIR)/JitsiMeetSDK/JitsiMeetSDK.framework/JitsiMeetSDK'
#      end
#    end
#  end
#end

