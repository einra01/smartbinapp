require 'json'

flutter_root = File.expand_path('..', __dir__)
podfile = File.join(flutter_root, 'ios', 'Podfile')

if File.exist?(podfile)
    pod_helper = File.join(flutter_root, '.flutter-plugins')
    if File.exist?(pod_helper)
        load(pod_helper)
    end
end
