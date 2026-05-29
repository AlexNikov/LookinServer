require_relative 'Scripts/lookin_src_manifest'

Pod::Spec.new do |spec|
  spec.name         = "LookinServer"
  spec.version      = "1.2.8"
  spec.summary      = "The iOS framework of Lookin with MCP support."
  spec.description  = "Embed this framework into your iOS project to enable Lookin mac app and lookin-mcp-ios integration."
  spec.homepage     = "https://lookin.work"
  spec.license      = "GPL-3.0"
  spec.author       = { "Li Kai" => "lookin@lookin.work" }
  spec.ios.deployment_target  = "14.0"
  spec.tvos.deployment_target  = "14.0"
  spec.visionos.deployment_target = "1.0"
  spec.default_subspecs = "Swift"
  spec.source       = { :git => "https://github.com/AlexNikov/LookinServer.git", :branch => "develop" }
  spec.framework    = "UIKit"
  spec.requires_arc = true
  spec.swift_version = "5.3"

  spec.prefix_header_contents = <<-'EOS'
    #ifdef __OBJC__
    @import Foundation;
    @import Dispatch;
    @import UIKit;
    #endif
  EOS

  unified_gcc_defs = [
    "SHOULD_COMPILE_LOOKIN_SERVER=1",
    "LOOKIN_UNIFIED_MODULE=1",
  ].join(" ")

  unified_swift_conditions = [
    "SHOULD_COMPILE_LOOKIN_SERVER",
  ].join(" ")

  spec.pod_target_xcconfig = {
    "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited) #{unified_gcc_defs}",
    "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited) #{unified_swift_conditions}",
    "HEADER_SEARCH_PATHS" => "$(inherited) ${PODS_TARGET_SRCROOT}/Sources/LookinServerBase",
    "CLANG_ALLOW_NON_MODULAR_INCLUDES_IN_FRAMEWORK_MODULES" => "YES",
    "OTHER_LDFLAGS" => "$(inherited) -undefined dynamic_lookup",
  }

  # Server: Swift in Sources/*; ObjC bridge + ivar trace via lookin_src_manifest.rb.
  spec.subspec "Server" do |ss|
    ss.source_files = LookinSrcManifest.server_pod_source_files + [
      "Sources/LookinServerShared/**/*.swift",
      "Sources/LookinServerPeertalk/**/*.swift",
      "Sources/LookinServerCategories/**/*.swift",
      "Sources/LookinServerOthers/**/*.swift",
      "Sources/LookinServerCore/**/*.swift",
      "Sources/LookinServerConnection/**/*.swift",
      "Sources/LookinServerConnectionBootstrap/**/*.swift",
    ]
    ss.exclude_files = [
      "Sources/LookinServerShared/LookinDefines.swift",
      "Sources/LookinServerShared/LookinAttrIdentifiers.swift",
      "Sources/LookinServerMCP/**/*",
      "Sources/LookinServer/**/*",
    ]
    ss.private_header_files = [
      "Sources/LookinServerBase/**/*.h",
    ]
  end

  spec.subspec "Swift" do |ss|
    ss.dependency "LookinServer/Server"
    ss.source_files = [
      "Sources/LookinServer/**/*",
    ]
    ss.exclude_files = [
      "Sources/LookinServerMCP/**/*",
    ]
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited)",
    }
  end

  spec.subspec "MCP" do |ss|
    ss.dependency "LookinServer/Swift"
    ss.source_files = [
      "Sources/LookinServerMCP/**/*.swift",
    ]
  end

  spec.subspec "NoHook" do |ss|
    ss.dependency "LookinServer/Server"
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
    }
  end

  spec.subspec "SwiftAndNoHook" do |ss|
    ss.dependency "LookinServer/Server"
    ss.source_files = [
      "Sources/LookinServer/**/*",
    ]
    ss.exclude_files = [
      "Sources/LookinServerMCP/**/*",
    ]
    ss.pod_target_xcconfig = {
      "GCC_PREPROCESSOR_DEFINITIONS" => "$(inherited)",
      "SWIFT_ACTIVE_COMPILATION_CONDITIONS" => "$(inherited)",
    }
  end
end
