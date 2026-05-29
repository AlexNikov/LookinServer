require_relative 'Scripts/lookin_src_manifest'

Pod::Spec.new do |spec|
  spec.name         = "LookinShared"
  spec.version      = "1.2.8"
  spec.summary      = "The shared files between client and server side of Lookin."
  spec.description  = "Embed this framework into your iOS project to enable Lookin mac app."
  spec.homepage     = "https://lookin.work"
  spec.license      = "GPL-3.0"
  spec.author       = { "Li Kai" => "lookin@lookin.work" }
  spec.ios.deployment_target  = "14.0"
  spec.tvos.deployment_target  = "14.0"
  spec.macos.deployment_target = "10.14"
  spec.visionos.deployment_target = "1.0"
  spec.source       = { :git => "https://github.com/AlexNikov/LookinServer.git", :branch => "develop" }
  spec.requires_arc = true
  spec.swift_version = "5.3"

  shared_gcc_defs = [
    "SHOULD_COMPILE_LOOKIN_SERVER=1",
    "LOOKIN_SERVER_SHARED_MODULE=1",
  ].join(" ")

  shared_swift_conditions = [
    "SHOULD_COMPILE_LOOKIN_SERVER",
  ].join(" ")

  shared_pod_headers = LookinSrcManifest.shared_pod_header_files

  # Swift wire models + Peertalk; transitional headers limited to Peertalk + Base trace.
  spec.source_files = shared_pod_headers + LookinSrcManifest::OBJC_EXCEPTION_CATCH_SOURCES + [
    "Sources/LookinServerBase/LookinIvarTrace.swift",
    "Sources/LookinServerShared/**/*.swift",
    "Sources/LookinServerCore/LookinDashboardBlueprint.swift",
    "Sources/LookinServerCore/LookinAttributeGetter.swift",
    "Sources/LookinServerPeertalk/**/*.swift",
    "Sources/LookinServerCategories/CALayer+Lookin.swift",
    "Sources/LookinServerCategories/NSSet+Lookin.swift",
    "Sources/LookinServerCategories/LookinAutoLayoutConstraint.swift",
  ]

  spec.exclude_files = [
    "Sources/LookinServerShared/LookinDefines.swift",
    "Sources/LookinServerShared/LKS_ObjectRegistry.swift",
  ]

  spec.public_header_files = shared_pod_headers

  spec.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) #{shared_gcc_defs}",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) #{shared_swift_conditions}",
    "HEADER_SEARCH_PATHS" => "$(inherited) ${PODS_TARGET_SRCROOT}/Sources/LookinServerBase",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES",
  }
end
