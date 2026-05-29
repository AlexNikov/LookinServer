# frozen_string_literal: true

# Ivar trace + ObjC exception catch for CocoaPods (unified LookinServer pod).
# Required from LookinServer*.podspec via:
#   require_relative 'Scripts/lookin_src_manifest'
module LookinSrcManifest
  BASE_SOURCES = ["Sources/LookinServerBase/**/*"].freeze

  OBJC_EXCEPTION_CATCH_SOURCES = [
    "Sources/LookinServerOthers/LookinObjCExceptionCatch.m",
  ].freeze

  SHARED_HEADER_GLOBS = [
    "Sources/LookinServerBase/**/*.h",
  ].freeze

  def self.server_pod_source_files
    BASE_SOURCES + OBJC_EXCEPTION_CATCH_SOURCES
  end

  def self.shared_pod_header_files
    SHARED_HEADER_GLOBS
  end
end
