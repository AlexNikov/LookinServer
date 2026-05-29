# CocoaPods helper for LookinServer (unified single-pod layout).
#
#   load File.expand_path('cocoapods/install.rb', __dir__)
#   install_lookin_server_pods!(git: 'https://github.com/AlexNikov/LookinServer.git', branch: 'develop', subspecs: ['Swift', 'MCP'])
#
# Or directly in Podfile:
#   pod 'LookinServer', :git => 'https://github.com/AlexNikov/LookinServer.git', :branch => 'develop', :subspecs => ['Swift', 'MCP']

def install_lookin_server_pods!(subspecs: ['Swift'], path: nil, git: nil, branch: nil, tag: nil, **options)
  source = lookin_server_source(path: path, git: git, branch: branch, tag: tag)
  pod 'LookinServer', source.merge(subspecs: Array(subspecs)).merge(options)
end

def lookin_server_source(path:, git:, branch:, tag:)
  if path
    { path: path }
  elsif git
    source = { git: git }
    source[:branch] = branch if branch
    source[:tag] = tag if tag
    unless branch || tag
      raise ArgumentError, 'install_lookin_server_pods!: specify branch: or tag: when using git:'
    end
    source
  else
    raise ArgumentError, 'install_lookin_server_pods!: specify path: or git:'
  end
end
