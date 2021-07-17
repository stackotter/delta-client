//
//  AssetError.swift
//  DeltaClient
//
//  Created by Rohan van Klinken on 3/7/21.
//

import Foundation

enum AssetError: LocalizedError {
  case versionsManifestFailure(Error)
  case versionManifestFailure(Error)
  case clientJarDownloadFailure
  case clientJarExtractionFailure
  case assetCopyFailure
  case blockTextureEnumerationFailure
  case dataProviderFailure
  case cgImageFailure
  case noURLForVersion(String)
  case failedToDownloadPixlyzerData(Error)
  case failedToWritePixlyzerData(Error)
  case failedToCreatePackMCMetaData
}
