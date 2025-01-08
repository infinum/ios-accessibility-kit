Pod::Spec.new do |s|
    s.name                  = 'AccessibilityKit'
    s.version               = '0.0.1'
    s.summary               = 'A helper tool for accessibility features of the app.'
    s.homepage              = 'https://github.com/infinum/AccessibilityKit'
    s.license               = { :type => 'Apache License, Version 2.0', :file => 'LICENSE' }
    s.author                = { 'Nikola Majcen' => 'nikola.majcen@infinum.com' }
    s.source                = { :git => 'https://github.com/infinum/AccessibilityKit.git', :tag => s.version.to_s }
    s.ios.deployment_target = '14.0'
    s.swift_version         = '5.0'
    s.source_files          = 'Sources/AccessibilityKit/Classes/**/*'
    s.resource_bundles      = { 'AccessibilityKit' => ['Sources/AccessibilityKit/Assets/**/*'] }
    
  end
  
