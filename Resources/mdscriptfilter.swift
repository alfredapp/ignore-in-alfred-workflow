import Foundation

// Prepare query
let query = CommandLine.arguments[1]
let searchQuery = MDQueryCreate(kCFAllocatorDefault, query as CFString, nil, nil)

// Run query
MDQueryExecute(searchQuery, CFOptionFlags(kMDQuerySynchronous.rawValue))
let resultCount = MDQueryGetResultCount(searchQuery)

// No results
guard resultCount > 0 else {
  print(
    """
    {\"items\":[{\"title\":\"No Results\",
    \"subtitle\":\"No paths found with 'alfred:ignore' tag\",
    \"valid\":false}]}
    """
  )

  exit(0)
}

// Prepare items
struct ScriptFilterItem: Codable {
  let uid: String
  let title: String
  let subtitle: String
  let type: String
  let icon: FileIcon
  let arg: String

  struct FileIcon: Codable {
    let path: String
    let type: String
  }
}

let sfItems: [ScriptFilterItem] = (0..<resultCount).compactMap { resultIndex in
  let rawPointer = MDQueryGetResultAtIndex(searchQuery, resultIndex)
  let resultItem = Unmanaged<MDItem>.fromOpaque(rawPointer!).takeUnretainedValue()

  guard let resultPath = MDItemCopyAttribute(resultItem, kMDItemPath) as? String else { return nil }

  return ScriptFilterItem(
    uid: resultPath,
    title: URL(fileURLWithPath: resultPath).lastPathComponent,
    subtitle: (resultPath as NSString).abbreviatingWithTildeInPath,
    type: "file",
    icon: ScriptFilterItem.FileIcon(path: resultPath, type: "fileicon"),
    arg: resultPath
  )
}

// Output JSON
let jsonData = try JSONEncoder().encode(["items": sfItems])
print(String(data: jsonData, encoding: .utf8)!)
