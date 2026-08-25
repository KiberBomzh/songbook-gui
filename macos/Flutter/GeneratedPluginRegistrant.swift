//
//  Generated file. Do not edit.
//

import FlutterMacOS
import Foundation

import file_picker
import package_info_plus
import restart_app
import share_plus
import shared_preferences_foundation
import wakelock_plus
import zikzak_share_handler_macos

func RegisterGeneratedPlugins(registry: FlutterPluginRegistry) {
  FilePickerPlugin.register(with: registry.registrar(forPlugin: "FilePickerPlugin"))
  FPPPackageInfoPlusPlugin.register(with: registry.registrar(forPlugin: "FPPPackageInfoPlusPlugin"))
  RestartAppPlugin.register(with: registry.registrar(forPlugin: "RestartAppPlugin"))
  SharePlusMacosPlugin.register(with: registry.registrar(forPlugin: "SharePlusMacosPlugin"))
  SharedPreferencesPlugin.register(with: registry.registrar(forPlugin: "SharedPreferencesPlugin"))
  WakelockPlusMacosPlugin.register(with: registry.registrar(forPlugin: "WakelockPlusMacosPlugin"))
  ShareHandlerMacosPlatform.register(with: registry.registrar(forPlugin: "ShareHandlerMacosPlatform"))
}
