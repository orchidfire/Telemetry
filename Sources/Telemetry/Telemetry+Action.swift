import Foundation

extension Telemetry {
   /**
    * Action call that can take type 
    * - Remark: The class support tracking of sessions, screen/page views, events and timings with optional custom dimension parameters.
    * - Remark: For a full list of all the supported parameters please refer to the [Google Analytics parameter reference](https://developers.google.com/analytics/devguides/collection/protocol/v1/parameters)
    * - Fixme: ⚠️️ add example
    * - Parameters:
    *   - action: - Fixme: ⚠️️ doc
    *   - complete: - Fixme: ⚠️️ dox
    */
   public static func action(_ action: ActionKind, complete: @escaping Complete = defaultComplete) {
      if case TMType.ga = tmType {
         send(type: action.key, parameters: action.output, complete: complete)
      } else if case TMType.agg(let agg) = tmType{
         do { try agg.append(action: action) }
         catch { Swift.print("error: \(error.localizedDescription)") }
      }
   }
}
/**
 * Helper
 */
extension Telemetry {
   /**
    * - Parameters:
    *   - send: timing, exception, pageview, session, exception etc
    *   - parameters: custom params for the type
    *   - type: - Fixme: ⚠️️ add doc
    *   - complete: - Fixme: ⚠️️ add doc
    */
   internal static func send(type: String?, parameters: [String: String], complete: @escaping Complete = defaultComplete) {
      guard let _ = trackerId else { Swift.print("No tracker ID"); return }
      var queryArgs = Self.queryArgs // Meta data
      if let type: String = type, !type.isEmpty {
         queryArgs.updateValue(type, forKey: "t")
      }
      if let customDim: [String: String] = self.customDimArgs {
         queryArgs.merge(customDim, uniquingKeysWith: { _, new in new })
      }
      queryArgs["aip"] = anonymizeIP ? "1" : nil
      let arguments = queryArgs.combinedWith(parameters)
      guard let url = Self.getURL(with: arguments) else { return }
      let task = session.dataTask(with: url) { _, _, error in
         if let errorResponse = error?.localizedDescription {
            Swift.print("Failed to deliver GA Request. ", errorResponse)
         }
         complete()
      }
      task.resume()
   }
}
/**
 * Private helpers
 */
extension Telemetry {
   /**
    * URL query (Meta data)
    */
   fileprivate static var queryArgs: [String: String] {
      guard let trackerId = Self.trackerId else { return [:] }
      return [
         "tid": trackerId, // GA tracker id
         "aid": System.appIdentifier, // App id
         "cid": Identity.uniqueUserIdentifier(type: idType), // User id
         "an": System.appName, // App name
         "av": System.formattedVersion, // App version and build
         "ua": System.userAgent, // Website meta data
         "ul": System.userLanguage, // Device language
         "sr": System.screenResolution, // Size of device screen
         "v": "1" // - Fixme: ⚠️️ What is this?
      ]
   }
   /**
    * URL
    * - Parameter parameters: parameters to turn into a url request
    */
   fileprivate static func getURL(with parameters: [String: String]) -> URL? {
      let characterSet: CharacterSet = CharacterSet.urlPathAllowed
      let joined: String = parameters.reduce("collect?") { path, query in
         let value = query.value.addingPercentEncoding(withAllowedCharacters: characterSet)
         return .init(format: "%@%@=%@&", path, query.key, value ?? "")
      }
      // Trim the trailing &
      let path: String = .init(joined[..<joined.index(before: joined.endIndex)])
      // Make sure we generated a valid URL
      guard let baseURL: URL = baseURL else { Swift.print("baseURL error"); return nil }
      guard let url: URL = .init(string: path, relativeTo: baseURL) else {
         Swift.print("Failed to generate a valid GA url for path ", path, " relative to ", baseURL.absoluteString)
         return nil
      }
      return url
   }
}