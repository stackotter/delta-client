//
//  GitHubWorkflowAPIResponse.swift
//  DeltaCore
//
//  Created by Rohan van Klinken on 28/9/21.
//

import Foundation

struct GitHubWorkflowAPIResponse: Codable {
  var workflowRuns: [WorkflowRun]
  
  struct WorkflowRun: Codable {
    var name: String
    var headBranch: String
    var headSha: String
    var status: String
    var conclusion: String
    var event: String
    var artifactsUrl: URL
    var checkSuiteId: Int
  }
}
