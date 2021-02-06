import Foundation

// PolicyManager resolves the app state, separating the UI from external actions,
// like interacting with the user, the OS or other parts of the environment.
class PolicyManager: ObservableObject {
    @Published var current: OSVersion
    
    init() {
        self.current = OSVersion(ProcessInfo().operatingSystemVersion)
    }
    
    init(withVersion: OSVersion) {
        self.current = withVersion
    }
}
