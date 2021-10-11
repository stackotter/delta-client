import Foundation

public enum PluginError: LocalizedError {
	case libraryOpenError(reason: String?)
	case builderNotFound
	case wrongAPIVersion
	case alreadyExists
	case invalidManifest
	case alternateRenderConflict
	
	public var errorDescription: String? {
		switch self {
		case .libraryOpenError(reason: let reason):
			return "Dynamic library opening failed\(reason != nil ? " (\(reason!))" : "")"
		case .builderNotFound:
			return "Builder function not found (the plugin may be incorrectly built or corrupted)"
		case .wrongAPIVersion:
			return "The plugin was created for the wrong version of DeltaPluginAPI"
		case .alreadyExists:
			return "A plugin with this name has already been loaded"
		case .invalidManifest:
			return "The plugin's manifest file is invalid"
		case .alternateRenderConflict:
			return "This plugin has an alternate render coordinator which conflicts with another plugin's alternate render system."
		}
	}
}
