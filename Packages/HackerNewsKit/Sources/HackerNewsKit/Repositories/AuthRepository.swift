import Foundation
import Alamofire
import Security
import SwiftSoup

public class AuthRepository {
    public static let shared: AuthRepository = .init()
    
    private let server: String = "news.ycombinator.com"
    private let baseUrl: String = "https://news.ycombinator.com"
    private let query: CFDictionary = [
        kSecClass: kSecClassInternetPassword,
        kSecAttrServer: "news.ycombinator.com",
        kSecReturnAttributes: true,
        kSecReturnData: true
    ] as [CFString : Any] as CFDictionary
    
    private init() {}
    
    public var username: String? {
        var result: AnyObject?
        _ = SecItemCopyMatching(query, &result)
        
        guard let dic = result as? NSDictionary else {
            return nil
        }
        
        let username = dic[kSecAttrAccount] as! String?
        
        return username
    }
    
    public var password: String? {
        var result: AnyObject?
        _ = SecItemCopyMatching(query, &result)
        
        guard let dic = result as? NSDictionary else {
            return nil
        }
        
        let passwordData = dic[kSecValueData] as! Data
        let password = String(data: passwordData, encoding: .utf8)
        
        return password
    }
    
    // MARK: - Authentication
    
    public func logIn(username: String, password: String, shouldRememberMe: Bool) async -> Bool {
        let parameters: [String: String] = [
            "acct": username,
            "pw": password
        ]
        let response = await AF.request("\(self.baseUrl)/login", method: .post, parameters: parameters, encoder: .urlEncodedForm).serializingString().response.response
        
        guard let url = response?.url else {
            return false
        }
        
        let cookies = HTTPCookieStorage.shared.cookies(for: url)
        let loggedIn = cookies.isNotNullOrEmpty
        
        if loggedIn && shouldRememberMe {
            let keychainItem = [
                kSecValueData: password.data(using: .utf8)!,
                kSecAttrAccount: username,
                kSecAttrServer: server,
                kSecClass: kSecClassInternetPassword,
                kSecReturnData: true,
                kSecReturnAttributes: true
            ] as [CFString : Any] as CFDictionary
            
            var ref: AnyObject?
            
            _ = SecItemAdd(keychainItem, &ref)
        }
        
        return loggedIn
    }
    
    public func logOut() -> Bool {
        guard let url = URL(string: baseUrl) else {
            return false
        }
        
        guard let cookies = HTTPCookieStorage.shared.cookies(for: url) else {
            return false
        }
        
        for cookie in cookies {
            HTTPCookieStorage.shared.deleteCookie(cookie)
        }
        
        let query = [
            kSecClass: kSecClassInternetPassword,
            kSecAttrServer: server,
            kSecReturnAttributes: true,
            kSecReturnData: true
        ] as [CFString : Any] as CFDictionary
        
        
        let delStatus = SecItemDelete(query)
        
        if delStatus != 0 {
            return false
        }
        
        return true
    }
    
    // MARK: - Actions that require authentication
    
    public func flag(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: Any] = [
            "acct": username,
            "pw": password,
            "id": id,
        ]
        
        return await performPost(data: parameters, path: "/flag")
    }
    
    public func upvote(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: Parameters = [
            "acct": username,
            "pw": password,
            "id": id,
            "how": "up",
        ]
        
        return await performPost(data: parameters, path: "/vote")
    }
    
    public func downvote(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: Any] = [
            "acct": username,
            "pw": password,
            "id": id,
            "how": "down",
        ]
        
        return await performPost(data: parameters, path: "/vote")
    }
    
    public func fav(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: Any] = [
            "acct": username,
            "pw": password,
            "id": id,
        ]
        
        return await performPost(data: parameters, path: "/fave")
    }
    
    public func unfav(_ id: Int) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: Any] = [
            "acct": username,
            "pw": password,
            "id": id,
            "un": "t",
        ]
        
        return await performPost(data: parameters, path: "/fave")
    }
    
    public func reply(to id: Int, with text: String) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        
        let parameters: [String: Any] = [
            "acct": username,
            "pw": password,
            "parent": id,
            "text": text,
        ]
        
        return await performPost(data: parameters, path: "/comment")
    }
    
    public func edit(_ id: Int, with text: String) async -> Bool {
        guard let username = self.username, let password = self.password else {
            return false
        }
        guard let response = try? await getFormResponse(username: username,
                                                        password: password,
                                                        path: "/edit",
                                                        id: id) else { return false }
        guard let url = URL(string: baseUrl),
              let cookies = HTTPCookieStorage.shared.cookies(for: url)
        else { return false }

        let headers = HTTPCookie.requestHeaderFields(with: cookies)
        guard let cookieString = headers["Cookie"] else { return false }
        guard let html = response.value,
              let hmac = Self.getHiddenFormValues(from: html, key: "hmac") else { return false }
        let parameters: [String: Any] = [
            "text": text,
            "id": id,
            "hmac": hmac,
        ]
        return await performPost(data: parameters, path: "/xedit", cookie: cookieString)
    }
}

private extension AuthRepository {
    private func getFormResponse(
        username: String,
        password: String,
        path: String,
        id: Int? = nil
    ) async throws -> DataResponse<String, AFError>? {
        guard let id, let url = URL(string: "\(baseUrl)\(path)?id=\(id)") else { throw URLError(.badURL) }
        let params: [String: Any] = [
            "acct": username,
            "pw": password,
            "id": id,
        ]
        let response = await AF.request(url,
                                        method: .post,
                                        parameters: params)
            .serializingString()
            .response
        return response
    }
    
    private func performPost(data: [String: Any], path: String, cookie: String? = nil) async -> Bool {
        HTTPCookieStorage.shared.removeCookies(since: Date.distantPast)
        var headers = [
            HTTPHeader(name: "content-type", value: "application/x-www-form-urlencoded")
        ]
        if let cookie {
            headers.append(HTTPHeader(name: "cookie", value: cookie))
        }
        let request = AF.request("\(baseUrl)\(path)",
                                 method: .post,
                                 parameters: data,
                                 headers: HTTPHeaders(headers))
        let res = await request.serializingString().response
        guard let statusCode = res.response?.statusCode, statusCode == 200 else { return false }
        return true
    }
    
    static func getHiddenFormValues(from input: String, key: String) -> String? {
        guard let body = try? SwiftSoup.parse(input).body(),
              let form = try? body.getElementsByTag("form").first()
        else { return nil }
        
        if let hiddenInputs = try? form.select("input[type=hidden]") {
            for element in hiddenInputs {
                if let name = try? element.attr("name"),
                   let value = try? element.attr("value"),
                   !name.isEmpty && name == key {
                    return value
                }
            }
        }
        
        return nil
    }
}
