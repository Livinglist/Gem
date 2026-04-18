import Combine
import Foundation
import Alamofire
import SwiftSoup

extension StoryRepository {
    static let favoritesBaseUrl =
        "https://news.ycombinator.com/favorites?id=";
    static let aThingSelector = "#hnmain .athing";
    
    public func fetchFavorites(of user: String, page: Int = 1, type: ItemType) async -> [Int] {
        let url = type == .story ? "\(Self.favoritesBaseUrl)\(user)&p=\(page)" : "\(Self.favoritesBaseUrl)\(user)&comments=t&p=\(page)"
        func fetchElements(page: Int) async throws -> Elements {
            do {
                let response = await AF.request(url).serializingString().response
                let html = try response.result.get()
                
                if html == "Sorry." {
                    throw AFError.sessionInvalidated(error: .none)
                }
                
                let document = try SwiftSoup.parse(html)
                let elements = try document.select(Self.aThingSelector);
                return elements
            } catch {
                if let e = error as? AFError {
                    switch e.responseCode {
                    case 403:
                        throw FetchError.rateLimited
                    default:
                        throw FetchError.networkError(e)
                    }
                }
                throw FetchError.generic(error)
            }
        }

        var fetchedCommentIds = [Int]()
        var elements: Elements
    
        do {
            elements = try await fetchElements(page: page);
        } catch {
            return []
        }
        
        for element in elements {
            /// Get item id.
            guard let cmtIdString = try? element.attr("id") else { continue }
            guard let cmtId = Int(cmtIdString) else { continue }
            fetchedCommentIds.append(cmtId)
        }

        return fetchedCommentIds
    }
}
