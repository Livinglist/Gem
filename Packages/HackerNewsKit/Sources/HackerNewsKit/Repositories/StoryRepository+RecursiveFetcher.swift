import Combine
import Foundation
import Alamofire
import SwiftSoup

public enum FetchError: Error {
    case noComment
    case possibleParsingFailure(Int)
    case rateLimited
    case networkError(AFError)
    case generic(Error)
}

extension StoryRepository {
    public func fetchCommentsRecursively(of item: any Item, from source: CommentSource) async throws -> [Comment] {
        var comments = [Comment]()
        switch source {
        case .API: comments = await fetchCommentsRecursivelyFromAPI(of: item)
        case .web: comments = try await fetchCommentsRecursivelyFromWeb(of: item)
        }
        
        let map = Dictionary(uniqueKeysWithValues: comments.map { ($0.id, $0) })
        for i in 0..<comments.count {
            let c = comments[i]
            guard let level = c.level else { continue }
            if level == 0 {
                continue
            } else if level == 1 && item.by == c.by {
                let updatedComment = c.copyWith(isReply: true)
                comments.replaceSubrange(i..<i + 1, with: [updatedComment])
                continue
            } else {
                guard let parentId = c.parent,
                      let parent = map[parentId],
                      let grandparentId = parent.parent,
                      let grandParent = map[grandparentId] else {
                    continue
                }
                if grandParent.by == c.by {
                    let updatedComment = c.copyWith(isReply: true)
                    comments.replaceSubrange(i..<i + 1, with: [updatedComment])
                }
            }
        }
        
        return comments
    }
    
    private func fetchCommentsRecursivelyFromAPI(of item: any Item, level: Int = 0) async -> [Comment] {
        guard let kids = item.kids else { return [] }
        let comments = await withTaskGroup(of: (Int, [Comment]).self) { group in
            for (index, kid) in kids.enumerated() {
                group.addTask { [self] in
                    guard var comment = await fetchComment(kid) else { return (index, []) }
                    comment = comment.copyWith(level: level)
                    let childComments = await fetchCommentsRecursivelyFromAPI(of: comment, level: level + 1)
                    return (index, [comment] + childComments)
                }
            }
            
            var comments: [(Int, [Comment])] = []
            for await result in group {
                comments.append(result)
            }
            return comments
                .sorted { $0.0 < $1.0 }
                .flatMap { $0.1 }
        }
        return comments
    }
}

extension StoryRepository {
    fileprivate static let itemBaseUrl = "https://news.ycombinator.com/item?id=";
    fileprivate static let athingComtrSelector = "#hnmain > tbody > tr > td > table > tbody > .athing.comtr";
    fileprivate static let commentTextSelector = "td > table > tbody > tr > td.default > div.comment > div.commtext";
    fileprivate static let commentHeaderSelector = "td > table > tbody > tr > td.default > div > span > a";
    fileprivate static let commentAgeSelector = "td > table > tbody > tr > td.default > div > span > span.age";
    fileprivate static let commentIndentSelector = "td > table > tbody > tr > td.ind";
    
    private func fetchCommentsRecursivelyFromWeb(of item: any Item) async throws -> [Comment] {
        var comments: [Comment] = []
        
        try await withCheckedThrowingContinuation { continuation in
            Task {
                try await fetchCommentsRecursivelyFromWeb(of: item) { comment in
                    if let comment {
                        comments.append(comment)
                    }
                }
                continuation.resume(returning: ())
            }
        }
        
        return comments
    }
    
    private func fetchCommentsRecursivelyFromWeb(of item: any Item, completion: @escaping (Comment?) -> Void) async throws {
        let itemId = item.id;
        let descendants = item is Story ? item.descendants : nil;
        var parentTextCount = 0
        let dateFormatter : DateFormatter = DateFormatter()
        let locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        dateFormatter.timeZone = .gmt
        dateFormatter.locale = locale

        func fetchElements(page: Int) async throws -> Elements {
            do {
                let url = "\(Self.itemBaseUrl)\(itemId)&p=\(page)"
                let response = await AF.request(url).serializingString().response
                let html = try response.result.get()
                
                if html == "Sorry." {
                    throw AFError.sessionInvalidated(error: .none)
                }
                
                if page == 1 {
                    parentTextCount = html.components(separatedBy:"parent").count - 1
                }
                
                let document = try SwiftSoup.parse(html)
                let elements = try document.select(Self.athingComtrSelector);
                
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
        
        if descendants == 0 || item.kids.isNullOrEmpty {
            completion(nil)
            return
        }
        
        var fetchedCommentIds = Set<Int>();
        var page = 1;
        var elements: Elements
        
        do {
            elements = try await fetchElements(page: page);
        } catch {
            completion(nil)
            throw error
        }
        
        var indentToParentId = Dictionary<Int, Int>();
        
        if item is Story && (item.descendants ?? 0) > 0 && elements.isEmpty {
            completion(nil)
            return
        }
        
        while elements.isEmpty == false {
            for element in elements {
                /// Get comment id.
                guard let cmtIdString = try? element.attr("id") else { continue }
                guard let cmtId = Int(cmtIdString) else { continue }
                
                /// Get comment text.
                guard let cmtTextElements = try? element.select(Self.commentTextSelector) else { continue }
                guard let cmtText = try? cmtTextElements.first()?.html() else { continue }
                let parsedText = parseCommentTextHtml(html: cmtText)
                
                /// Get comment author.
                guard let cmtHeadElements = try? element.select(Self.commentHeaderSelector) else { continue }
                guard let cmtAuthor = try? cmtHeadElements.first()?.text() else { continue }
                
                /// Get comment age.
                guard let cmtAgeElements = try? element.select(Self.commentAgeSelector) else { continue }
                guard let ageString = try? cmtAgeElements.attr("title").components(separatedBy: .whitespaces).first else { continue }
                guard let timestamp = dateFormatter.date(from: ageString)?.timeIntervalSince1970 else { continue }

                /// Get comment indent.
                guard let cmtIndentElements = try? element.select(Self.commentIndentSelector) else { continue }
                let indentString = try? cmtIndentElements.attr("indent")
                let indent = Int(indentString ?? String()) ?? 0

                indentToParentId[indent] = cmtId
                let parentId = indentToParentId[indent - 1] ?? -1
                
                let cmt = Comment(id: cmtId, 
                                  parent: parentId,
                                  text: parsedText,
                                  by: cmtAuthor,
                                  time: Int(timestamp),
                                  level: indent)
                
                fetchedCommentIds.insert(cmt.id)
                completion(cmt)
            }
            
            /// If we didn't successfully got any comment on first page,
            /// and we are sure there are comments there based on the count of
            /// 'parent' text, then this might be a parsing error and possibly is
            /// caused by HN changing their HTML structure, therefore here we
            /// throw an error so that we can fallback to use API instead.
            if page == 1 && parentTextCount > 0 && fetchedCommentIds.isEmpty {
                completion(nil)
                return
            }
            
            if let descendants = descendants, fetchedCommentIds.count >= descendants {
                completion(nil)
                return
            }
            
            page+=1;
            do {
                elements = try await fetchElements(page: page);
            } catch {
                elements = Elements()
            }
        }
        
        completion(nil)
        return
    }
    
    fileprivate func parseCommentTextHtml(html: String) -> String {
        do {
            let replyRegex = try Regex(#"\<div class="reply"\>(.*?)\<\/div\>"#).dotMatchesNewlines()
            let spanRegex = try Regex(#"\<span class="(.*?)"\>(.*?)\<\/span\>"#).dotMatchesNewlines()
            let pRegex = try Regex(#"\<p\>(.*?)\<\/p\>"#).dotMatchesNewlines()
            let codeRegex = try Regex(#"\<pre\>\<code\>(.*?)\<\/code\>\<\/pre\>"#).dotMatchesNewlines()
            let linkRegex = try Regex(#"\<a href=\"(.*?)\".*?\>.*?\<\/a\>"#)
            let iRegex = try Regex(#"\<i\>(.*?)\<\/i\>"#)
            let res = try Entities.unescape(html)
                .replacing(replyRegex) { _ in String() }
                .replacing(spanRegex) { match in
                    if let m = match[2].substring {
                        let matchedStr = String(m)
                        return "\(matchedStr)"
                    }
                    return String()
                }
                .replacing(pRegex) { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return "\n\(matchedStr)"
                    }
                    return String()
                }
                .replacing(linkRegex) { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return matchedStr
                    }
                    return String()
                }
                .replacing(iRegex) { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return "**\(matchedStr)**"
                    }
                    return String()
                }
                .replacing(codeRegex, with: { match in
                    if let m = match[1].substring {
                        let matchedStr = String(m)
                        return "```\n" + matchedStr.replacing("\n", with: "``` \n ``` \n") + "\n```\n"
                    }
                    return String()
                })
            return res.trimmingCharacters(in: .whitespacesAndNewlines)
        } catch {
            return error.localizedDescription
        }
    }
}
